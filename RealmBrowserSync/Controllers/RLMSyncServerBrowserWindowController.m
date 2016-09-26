////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
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

@import Realm.Dynamic;
@import Realm.Private;

#import "RLMSyncServerBrowserWindowController.h"
#import "RLMDynamicSchemaLoader.h"

static  NSString * const RLMAdminRealmServerPath = @"__admin";

@interface RLMSyncServerBrowserWindowController ()<NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, weak) IBOutlet NSTableView *tableView;
@property (nonatomic, weak) IBOutlet NSProgressIndicator *progressIndicator;

@property (nonatomic, strong) NSURL *selectedURL;

@property (nonatomic, strong) NSURL *serverURL;

@property (nonatomic, strong) NSURL *adminRealmSyncURL;

@property (nonatomic, strong) RLMSyncUser *user;

@property (nonatomic, strong) RLMDynamicSchemaLoader *schemaLoader;
@property (nonatomic, strong) RLMNotificationToken *notificationToken;
@property (nonatomic, strong) RLMResults *realmFiles;

@end

@implementation RLMSyncServerBrowserWindowController

- (instancetype)initWithServerURL:(NSURL *)serverURL user:(RLMSyncUser *)user {
    self = [super init];

    if (self != nil) {
        self.serverURL = serverURL;
        self.adminRealmSyncURL = [serverURL URLByAppendingPathComponent:RLMAdminRealmServerPath];
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
    [self.schemaLoader loadSchemaWithCompletionHandler:^(NSError *error) {
        if (error != nil) {
            [weakSelf.progressIndicator stopAnimation:nil];
            weakSelf.progressIndicator.hidden = YES;

            [[NSAlert alertWithError:error] beginSheetModalForWindow:weakSelf.window completionHandler:^(NSModalResponse returnCode) {
                [weakSelf close];
            }];
        } else {
            [weakSelf openAdminRealmWithUser:weakSelf.user];
        }
    }];
}

- (void)openAdminRealmWithUser:(RLMSyncUser *)user {
    RLMRealmConfiguration *configuration = [[RLMRealmConfiguration alloc] init];
    configuration.dynamic = YES;
    configuration.syncConfiguration = [[RLMSyncConfiguration alloc] initWithUser:user realmURL:self.adminRealmSyncURL];

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
    self.selectedURL = self.tableView.selectedRow >= 0 ? [[NSURL alloc] initWithString:[self.realmFiles[self.tableView.selectedRow] valueForKey:@"path"] relativeToURL:self.serverURL] : nil;
}

@end

