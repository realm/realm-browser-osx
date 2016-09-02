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

@property (nonatomic, strong) NSURL *selectedURL;

@property (nonatomic, strong) NSURL *serverURL;

@property (nonatomic, strong) NSURL *adminRealmSyncURL;
@property (nonatomic, strong) NSURL *adminRealmFileURL;

@property (nonatomic, strong) RLMUser *user;

@property (nonatomic, strong) RLMDynamicSchemaLoader *schemaLoader;
@property (nonatomic, strong) RLMNotificationToken *notificationToken;
@property (nonatomic, strong) RLMResults *realmFiles;

@end

@implementation RLMSyncServerBrowserWindowController

- (instancetype)initWithServerURL:(NSURL *)serverURL user:(RLMUser *)user {
    self = [super init];

    if (self != nil) {
        self.serverURL = serverURL;

        self.adminRealmSyncURL = [serverURL URLByAppendingPathComponent:RLMAdminRealmServerPath];
        self.adminRealmFileURL = [self temporaryURLForRealmFileWithSync:self.adminRealmSyncURL.lastPathComponent];

        self.user = user;

        self.schemaLoader = [[RLMDynamicSchemaLoader alloc] initWithSyncURL:self.adminRealmSyncURL user:self.user];
    }

    return self;
}

- (void)dealloc {
    [self.notificationToken stop];
}

- (void)windowDidLoad {
    [super windowDidLoad];

    self.tableView.hidden = YES;
}

- (void)showWindow:(id)sender {
    [super showWindow:sender];

    [self.progressIndicator startAnimation:nil];

    __weak typeof(self) weakSelf = self;
    [self.schemaLoader loadSchemaToURL:self.adminRealmFileURL completionHandler:^(NSError *error) {
        if (error != nil) {
            [weakSelf.progressIndicator stopAnimation:nil];
            weakSelf.progressIndicator.hidden = YES;

            [[NSAlert alertWithError:error] beginSheetModalForWindow:weakSelf.window completionHandler:^(NSModalResponse returnCode) {
                [weakSelf close];
            }];
        } else {
            [weakSelf openAdminRealmAtURL:weakSelf.adminRealmFileURL user:weakSelf.user];
        }
    }];
}

- (void)openAdminRealmAtURL:(NSURL *)fileURL user:(RLMUser *)user {
    RLMRealmConfiguration *configuration = [[RLMRealmConfiguration alloc] init];
    configuration.dynamic = YES;
    configuration.customSchema = nil;

    [configuration setObjectServerPath:RLMAdminRealmServerPath forUser:user];

    if (fileURL != nil) {
        configuration.fileURL = fileURL;
    }

    RLMRealm *realm = [RLMRealm realmWithConfiguration:configuration error:nil];

    __weak typeof(self) weekSelf = self;
    self.notificationToken = [realm addNotificationBlock:^(RLMNotification  _Nonnull notification, RLMRealm * _Nonnull realm) {
        [weekSelf.tableView reloadData];
    }];

    self.realmFiles = [realm allObjects:@"RealmFile"];

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
    [self closeWithReturnCode:NSModalResponseOK];
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
    self.selectedURL = self.tableView.selectedRow >= 0 ? [self.serverURL URLByAppendingPathComponent:[self.realmFiles[self.tableView.selectedRow] valueForKey:@"path"]] : nil;
}

@end

