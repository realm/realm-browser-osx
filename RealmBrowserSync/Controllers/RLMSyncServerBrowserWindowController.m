//
//  RLMSyncServerBrowserWindowController.m
//  RealmBrowser
//
//  Created by Dmitry Obukhov on 11/08/16.
//  Copyright © 2016 Realm inc. All rights reserved.
//

@import Realm;
@import Realm.Private;
@import Realm.Dynamic;
#import "RLMSyncServerBrowserWindowController.h"

@interface RLMSyncServerBrowserWindowController ()<NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, weak) IBOutlet NSTableView *tableView;
@property (nonatomic, weak) IBOutlet NSProgressIndicator *progressIndicator;

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

- (NSModalResponse)connectToServerAtURL:(NSURL *)url accessToken:(NSString *)token error:(NSError **)error {
    __autoreleasing NSError *localError;
    if (error == NULL) {
        error = &localError;
    }

    RLMRealmConfiguration *configuration = [self adminRealmConfigurationForServerURL:url accessToken:token];
    RLMRealm *initialRealm = [RLMRealm realmWithConfiguration:configuration error:error];

    if (initialRealm == nil) {
        return NSModalResponseAbort;
    }

    __block RLMNotificationToken *initialNotificationToken = [initialRealm addNotificationBlock:^(RLMNotification  _Nonnull notification, RLMRealm * _Nonnull realm) {
        [initialNotificationToken stop];
        [self setupRealmAfterInitialSyncWithConfiguration:configuration];
    }];

    [self performSelector:@selector(hadleRealmSchemaLoadTimeout) withObject:nil afterDelay:5];

    self.window.title = url.host;
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

    if (result == NSModalResponseAbort) {
        *error = [[NSError alloc] initWithDomain:@"io.realm.realmbrowser.sync" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Error connecting to Sync Server"}];
    }

    [initialNotificationToken stop];
    [self.notificationToken stop];
    self.realm = nil;

    [self close];

    return result;
}

- (void)setupRealmAfterInitialSyncWithConfiguration:(RLMRealmConfiguration *)configuration {
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

- (void)hadleRealmSchemaLoadTimeout {
    [NSApp stopModalWithCode:NSModalResponseAbort];
}

- (RLMRealmConfiguration *)adminRealmConfigurationForServerURL:(NSURL *)url accessToken:(NSString *)token {
    RLMCredential *credential = [RLMCredential credentialWithAccessToken:token serverURL:url];
    RLMUser *user = [[RLMUser alloc] initWithLocalIdentity:nil];
    [user loginWithCredential:credential completion:nil];

    RLMRealmConfiguration *configuration = [[RLMRealmConfiguration alloc] init];
    configuration.dynamic = YES;
    configuration.customSchema = nil;

    [configuration setObjectServerPath:@"admin" forUser:user];
    configuration.fileURL = [self temporaryURLForRealmFileWithSync:@"admin"];

    return configuration;
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

