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

#import "RLMDocument.h"

#import "RLMBrowserConstants.h"
#import "RLMClassNode.h"
#import "RLMArrayNode.h"
#import "RLMClassProperty.h"
#import "RLMRealmOutlineNode.h"
#import "RLMRealmBrowserWindowController.h"
#import "RLMAlert.h"

#import <AppSandboxFileAccess/AppSandboxFileAccess.h>
#import "NSURLComponents+FragmentItems.h"

@interface RLMDocument ()

@property (nonatomic, assign, readwrite) BOOL potentiallyEncrypted;
@property (nonatomic, assign, readwrite) BOOL potentiallySync;
@property (nonatomic, strong) NSURL *securityScopedURL;
@property (nonatomic) RLMNotificationToken *changeNotificationToken;

@end

@implementation RLMDocument

- (instancetype)initWithContentsOfURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
    __block BOOL success = NO;
    
    if (self = [super init]) {
        if (![[typeName lowercaseString] isEqualToString:kRealmUTIIdentifier]) {
            return nil;
        }
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:absoluteURL.path]) {
            return nil;
        }
        NSString *lastComponent = [absoluteURL lastPathComponent];
        NSString *extension = [absoluteURL pathExtension];
        
        if (![[extension lowercaseString] isEqualToString:kRealmFileExtension]) {
            return nil;
        }
        
        NSURLComponents *components = [NSURLComponents componentsWithURL:absoluteURL resolvingAgainstBaseURL:NO];
        NSDictionary *fragmentsDictionary = components.fragmentItemsDictionary;
        
        BOOL showSyncRealmPrompt = (fragmentsDictionary[@"syncCredentialsPrompt"] != nil);
        
        NSURL *folderURL = absoluteURL;
        BOOL isDir = NO;
        if (([[NSFileManager defaultManager] fileExistsAtPath:folderURL.path isDirectory:&isDir] && isDir == NO)) {
            folderURL = [folderURL URLByDeletingLastPathComponent];
        }
        
        // In case we're trying to open Realm file located in app's container directory there is no reason to ask access permissions
        if (![[NSFileManager defaultManager] isWritableFileAtPath:folderURL.path]) {
            [[AppSandboxFileAccess fileAccess] requestAccessPermissionsForFileURL:folderURL persistPermission:YES withBlock:^(NSURL *securityScopedFileURL, NSData *bookmarkData) {
                self.securityScopedURL = securityScopedFileURL;
            }];
            
            if (self.securityScopedURL == nil) {
                return nil;
            }
        }
        
        NSArray *fileNameComponents = [lastComponent componentsSeparatedByString:@"."];
        NSString *realmName = [fileNameComponents firstObject];
        
        RLMRealmNode *realmNode = [[RLMRealmNode alloc] initWithName:realmName url:absoluteURL.path];
        __weak typeof(self) weakSelf = self;
        
        realmNode.syncServerURL = fragmentsDictionary[@"syncServerURL"];
        realmNode.syncSignedUserToken = fragmentsDictionary[@"syncSignedUserToken"];
        
        self.fileURL = absoluteURL;
        
        void (^mainThreadBlock)() = ^{
            [self.securityScopedURL startAccessingSecurityScopedResource];
            
            //Check to see if first the Realm file needs upgrading, and
            //if it does, prompt the user to confirm with proceeding
            if ([realmNode realmFileRequiresFormatUpgrade]) {
                if (![RLMAlert showFileFormatUpgradeDialogWithFileName:realmName]) {
                    return;
                }
            }

            NSError *error;
            if ([realmNode connect:&error] || error.code == 2) {
                if (error) {
                    if (![RLMAlert showEncryptionConfirmationDialogWithFileName:realmName])
                        return;

                    weakSelf.potentiallyEncrypted = YES;
                }

                weakSelf.presentedRealm  = realmNode;

                weakSelf.changeNotificationToken = [realmNode.realm addNotificationBlock:^(NSString *notification, RLMRealm *realm) {
                    for (RLMRealmBrowserWindowController *windowController in weakSelf.windowControllers) {
                        [windowController reloadAfterEdit];
                    }
                }];

                NSDocumentController *documentController = [NSDocumentController sharedDocumentController];
                [documentController noteNewRecentDocumentURL:absoluteURL];

                for (RLMRealmBrowserWindowController *windowController in weakSelf.windowControllers) {
                    [windowController realmDidLoad];
                }

                success = YES;
            } else if (error) {
                [[NSApplication sharedApplication] presentError:error];
            }
        };

        // If RLMDocument is instantiated on the main thread, dispatching
        // that block synchronously will freeze the app.
        if (![NSThread isMainThread]) {
            dispatch_sync(dispatch_get_main_queue(), mainThreadBlock);
        } else {
            mainThreadBlock();
        }
    }
    
    return success ? self : nil;
}

- (id)initForURL:(NSURL *)urlOrNil withContentsOfURL:(NSURL *)contentsURL ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    return nil;
}

- (void)dealloc
{
    [self.changeNotificationToken stop];

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

#pragma mark - Public methods - NSDocument overrides - Creating and Managing Window Controllers

- (void)makeWindowControllers
{
    RLMRealmBrowserWindowController *windowController = [[RLMRealmBrowserWindowController alloc] initWithWindowNibName:self.windowNibName];
    windowController.modelDocument = self;
    [self addWindowController:windowController];
}

- (NSString *)windowNibName
{
    return @"RLMDocument";
}

#pragma mark - Public methods - NSDocument overrides - Loading Document Data

+ (BOOL)canConcurrentlyReadDocumentsOfType:(NSString *)typeName
{
    return YES;
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

#pragma mark - Public methods - NSDocument overrides - Managing Document Windows

- (NSString *)displayName
{
    if (self.presentedRealm.name != nil) {
        return self.presentedRealm.name;
    }
    
    return [super displayName];
}

@end
