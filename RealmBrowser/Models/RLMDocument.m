////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014-2015 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

@import Realm;
@import AppSandboxFileAccess;

#import "RLMDocument.h"
#import "RLMBrowserConstants.h"
#import "RLMDynamicSchemaLoader.h"
#import "RLMRealmBrowserWindowController.h"

@interface RLMDocument ()

@property (nonatomic, strong) NSURL *securityScopedURL;

@property (nonatomic, copy) NSURL *syncURL;
@property (nonatomic, strong) RLMUser *user;
@property (nonatomic, strong) RLMDynamicSchemaLoader *schemaLoader;

@end

@implementation RLMDocument

- (instancetype)initWithContentsOfURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
    if (![typeName.lowercaseString isEqualToString:kRealmUTIIdentifier]) {
        return nil;
    }

    if (absoluteURL.isFileURL) {
        return [self initWithContentsOfFileURL:absoluteURL error:outError];
    } else {
        return [self initWithContentsOfSyncURL:absoluteURL credential:nil error:outError];
    }
}

- (instancetype)initWithContentsOfFileURL:(NSURL *)fileURL error:(NSError **)outError {
    if (![fileURL.pathExtension.lowercaseString isEqualToString:kRealmFileExtension]) {
        return nil;
    }

    BOOL isDir = NO;
    if (!([[NSFileManager defaultManager] fileExistsAtPath:fileURL.path isDirectory:&isDir] && isDir == NO)) {
        return nil;
    }

    NSURL *folderURL = fileURL.URLByDeletingLastPathComponent;

    self = [super init];

    if (self != nil) {
        self.fileURL = fileURL;

        // In case we're trying to open Realm file located in app's container directory there is no reason to ask access permissions
        if (![[NSFileManager defaultManager] isWritableFileAtPath:folderURL.path]) {
            [[AppSandboxFileAccess fileAccess] requestAccessPermissionsForFileURL:folderURL persistPermission:YES withBlock:^(NSURL *securityScopedFileURL, NSData *bookmarkData) {
                self.securityScopedURL = securityScopedFileURL;
            }];

            if (self.securityScopedURL == nil) {
                return nil;
            }
        }

        [self.securityScopedURL startAccessingSecurityScopedResource];

        self.presentedRealm = [[RLMRealmNode alloc] initWithFileURL:self.fileURL];

        if ([self.presentedRealm realmFileRequiresFormatUpgrade]) {
            self.state = RLMDocumentStateRequiresFormatUpgrade;
        } else {
            NSError *error;
            if (![self loadWithError:&error]) {
                if (error.code == RLMErrorFileAccess) {
                    self.state = RLMDocumentStateNeedsEncryptionKey;
                } else {
                    if (outError != nil) {
                        *outError = error;
                    }

                    return nil;
                }
            }
        }
    }

    return self;
}

- (instancetype)initWithContentsOfSyncURL:(NSURL *)syncURL credential:(RLMCredential *)credential error:(NSError **)outError {
    self = [super init];

    if (self != nil) {
        self.syncURL = syncURL;
        self.fileURL = [self temporaryFileURLForSyncURL:syncURL];
        self.user = [[RLMUser alloc] initWithLocalIdentity:nil];

        self.presentedRealm = [[RLMRealmNode alloc] initWithFileURL:self.fileURL syncURL:self.syncURL user:self.user];

        self.state = RLMDocumentStateNeedsValidCredential;

        if (credential != nil) {
            [self loadWithCredential:credential completionHandler:nil];
        }
    }

    return self;
}

- (void)dealloc
{
    if (self.securityScopedURL != nil) {
        //In certain instances, RLMRealm's C++ destructor method will attempt to clean up
        //specific auxiliary files belonging to this realm file.
        //If the destructor call occurs after the access to the sandbox resource has been released here,
        //and it attempts to delete any files, RLMRealm will throw an exception.
        //Mac OS X apps only have a finite number of open sandbox resources at any given time, so while it's not necessary
        //to release them straight away, it is still good practice to do so eventually.
        //As such, this will release the handle a minute, after closing the document.
        NSURL *scopedURL = self.securityScopedURL;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [scopedURL stopAccessingSecurityScopedResource];
        });
    }
}

- (BOOL)loadByPerformingFormatUpgradeWithError:(NSError **)error {
    NSAssert(self.state == RLMDocumentStateRequiresFormatUpgrade, @"Invalid document state");

    return [self loadWithError:error];
}

- (BOOL)loadWithEncryptionKey:(NSData *)key error:(NSError **)error {
    NSAssert(self.state == RLMDocumentStateNeedsEncryptionKey, @"Invalid document state");

    self.presentedRealm.encryptionKey = key;

    return [self loadWithError:error];
}

- (void)loadWithCredential:(RLMCredential *)credential completionHandler:(void (^)(NSError *error))completionHandler {
    NSAssert(self.state == RLMDocumentStateNeedsValidCredential, @"Invalid document state");

    completionHandler = completionHandler ?: ^(NSError *error) {};

    __weak typeof(self) weakSelf = self;

    self.state = RLMDocumentStateLoadingSchema;

    [self.user loginWithCredential:credential completion:^(NSError *error) {
        if (error != nil) {
             self.state = RLMDocumentStateNeedsValidCredential;

            completionHandler(error);
            return;
        }

        weakSelf.schemaLoader = [[RLMDynamicSchemaLoader alloc] initWithSyncURL:self.syncURL user:weakSelf.user];

        [weakSelf.schemaLoader loadSchemaToURL:weakSelf.fileURL completionHandler:^(NSError *error) {
            if (error == nil) {
                [weakSelf loadWithError:&error];
            }

            // FIXME: we should have `RLMDocumentStateLoaded` here or unrecoverable error.

            completionHandler(error);
        }];
    }];
}

- (BOOL)loadWithError:(NSError **)error {
    if (![self.presentedRealm connect:error]) {
        return NO;
    }

    self.state = RLMDocumentStateLoaded;

    return YES;
}

#pragma mark NSDocument overrides

- (void)makeWindowControllers
{
    RLMRealmBrowserWindowController *windowController = [[RLMRealmBrowserWindowController alloc] initWithWindowNibName:self.windowNibName];
    [self addWindowController:windowController];
}

- (NSString *)windowNibName
{
    return @"RLMDocument";
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    // As we do not use the usual file handling mechanism we just returns nil (but it is necessary
    // to override this method as the default implementation throws an exception.
    return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    // As we do not use the usual file handling mechanism we just returns YES (but it is necessary
    // to override this method as the default implementation throws an exception.
    return YES;
}

- (NSString *)displayName
{
    return self.syncURL ? self.syncURL.absoluteString : self.fileURL.lastPathComponent.stringByDeletingPathExtension;
}

#pragma mark Private

- (NSURL *)temporaryFileURLForSyncURL:(NSURL *)syncURL {
    NSString *fileName = syncURL.lastPathComponent;

    if (![fileName.pathExtension isEqualToString:kRealmFileExtension]) {
        fileName = [fileName stringByAppendingPathExtension:kRealmFileExtension];
    }

    NSURL *directoryURL = [NSURL fileURLWithPath:NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject];
    directoryURL = [directoryURL URLByAppendingPathComponent:[NSBundle mainBundle].bundleIdentifier];
    directoryURL = [directoryURL URLByAppendingPathComponent:[NSUUID UUID].UUIDString];

    [[NSFileManager defaultManager] createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:nil];

    return [directoryURL URLByAppendingPathComponent:fileName];
}

@end
