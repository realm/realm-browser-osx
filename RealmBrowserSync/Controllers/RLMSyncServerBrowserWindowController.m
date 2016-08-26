//
//  RLMSyncServerBrowserWindowController.m
//  RealmBrowser
//
//  Created by Dmitry Obukhov on 11/08/16.
//  Copyright © 2016 Realm inc. All rights reserved.
//

@import Realm;
@import Realm.Dynamic;
@import Realm.Private;

#import "RLMSyncServerBrowserWindowController.h"
#import "RLMDynamicSchemaLoader.h"

static  NSString * const RLMAdminRealmServerPath = @"admin";

@interface RLMSyncServerBrowserWindowController ()<NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, weak) IBOutlet NSTableView *tableView;
@property (nonatomic, weak) IBOutlet NSProgressIndicator *progressIndicator;

@property (nonatomic, strong) RLMDynamicSchemaLoader *schemaLoader;

@property (nonatomic, strong) RLMRealm *realm;
@property (nonatomic, strong) RLMNotificationToken *notificationToken;
@property (nonatomic, strong) RLMResults *realmFiles;

@property (nonatomic, strong) NSString *selectedRealmPath;

@property (nonatomic, assign) NSModalSession modalSession;

@end

@implementation RLMSyncServerBrowserWindowController

- (instancetype)init {
    self = [super initWithWindowNibName:@"SyncServerBrowserWindow"];

    if (self) {
        [self loadWindow];
    }

    return self;
}

- (NSModalResponse)connectToServerAtURL:(NSURL *)serverURL adminAccessToken:(NSString *)accessToken error:(NSError **)error {
    __autoreleasing NSError *localError;
    if (error == NULL) {
        error = &localError;
    }

    NSURL *adminRealmSyncURL = [serverURL URLByAppendingPathComponent:RLMAdminRealmServerPath];
    NSURL *adminRealmFileURL = [self temporaryURLForRealmFileWithSync:adminRealmSyncURL.lastPathComponent];

    RLMCredential *credential = [RLMCredential credentialWithAccessToken:accessToken serverURL:serverURL];

    RLMUser *user = [[RLMUser alloc] initWithLocalIdentity:nil];
    [user loginWithCredential:credential completion:nil];

    self.schemaLoader = [[RLMDynamicSchemaLoader alloc] initWithSyncURL:adminRealmSyncURL user:user];
    [self.schemaLoader loadSchemaToURL:adminRealmFileURL completionHandler:^(NSError *schemaLoadError) {
        if (schemaLoadError != nil) {
            *error = schemaLoadError;
            [NSApp stopModalWithCode:NSModalResponseAbort];
        } else {
            [self openAdminRealmAtURL:adminRealmFileURL user:user];
        }
    }];

    self.window.title = serverURL.host;
    [self.window center];
    [self.progressIndicator startAnimation:nil];
    self.tableView.hidden = YES;

    NSModalSession session = [NSApp beginModalSessionForWindow:self.window];
    NSModalResponse result = NSRunContinuesResponse;

    while (result == NSRunContinuesResponse) {
        result = [NSApp runModalSession:session];
        [[NSRunLoop currentRunLoop] limitDateForMode:NSDefaultRunLoopMode];
    }
    
    [NSApp endModalSession:session];

    [self.notificationToken stop];
    self.realm = nil;

    [self close];

    return result;
}

- (void)openAdminRealmAtURL:(NSURL *)fileURL user:(RLMUser *)user {
    RLMRealmConfiguration *configuration = [[RLMRealmConfiguration alloc] init];
    configuration.dynamic = YES;
    configuration.customSchema = nil;

    [configuration setObjectServerPath:RLMAdminRealmServerPath forUser:user];

    if (fileURL != nil) {
        configuration.fileURL = fileURL;
    }

    self.realm = [RLMRealm realmWithConfiguration:configuration error:nil];

    __weak typeof(self) weekSelf = self;
    self.notificationToken = [self.realm addNotificationBlock:^(RLMNotification  _Nonnull notification, RLMRealm * _Nonnull realm) {
        [weekSelf.tableView reloadData];
    }];

    self.realmFiles = [self.realm allObjects:@"RealmFile"];

    [self.progressIndicator stopAnimation:nil];
    self.progressIndicator.hidden = YES;

    self.tableView.hidden = NO;
    [self.tableView reloadData];
}

- (NSURL *)temporaryURLForRealmFileWithSync:(NSString *)realmFileName {
    NSString *uniqueString = [NSUUID UUID].UUIDString;

    if (realmFileName == nil) {
        realmFileName = uniqueString;
    }

    if (![realmFileName.pathExtension isEqualToString:@"realm"]) {
        realmFileName = [realmFileName stringByAppendingPathExtension:@"realm"];
    }

    NSString *tempDirectoryPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"io.realm.realmbrowser"] stringByAppendingPathComponent:uniqueString];

    [[NSFileManager defaultManager] createDirectoryAtPath:tempDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];

    return [NSURL fileURLWithPath:[tempDirectoryPath stringByAppendingPathComponent:realmFileName]];
}

- (IBAction)open:(id)sender {
    [NSApp stopModalWithCode:NSModalResponseOK];
}

#pragma mark - NSWindowDelegate

- (BOOL)windowShouldClose:(id)sender {
    [NSApp stopModalWithCode:NSModalResponseCancel];
    return YES;
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.realmFiles.count;
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"PathCell" owner:self];

    cellView.textField.stringValue = [self.realmFiles[row] valueForKey:@"path"];

    return cellView;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    self.selectedRealmPath = self.tableView.selectedRow >= 0 ? [self.realmFiles[self.tableView.selectedRow] valueForKey:@"path"] : nil;
}

@end

