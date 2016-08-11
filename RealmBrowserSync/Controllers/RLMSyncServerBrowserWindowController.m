//
//  RLMSyncServerBrowserWindowController.m
//  RealmBrowser
//
//  Created by Dmitry Obukhov on 11/08/16.
//  Copyright © 2016 Realm inc. All rights reserved.
//

@import Realm;
@import Realm.Private;
#import "RLMSyncServerBrowserWindowController.h"

@interface RLMSyncServerBrowserWindowController ()<NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, weak) IBOutlet NSTableView *tableView;

@property (nonatomic, strong) RLMRealm *realm;
@property (nonatomic, strong) RLMNotificationToken *notificationToken;

@property (nonatomic, strong) NSString *selectedRealmPath;

@end

@implementation RLMSyncServerBrowserWindowController

- (instancetype)init
{
    self = [super initWithWindowNibName:@"SyncServerBrowserWindow"];

    if (self) {
        [self loadWindow];
    }

    return self;
}

- (NSModalResponse)connectToServerAtURL:(NSURL *)url accessToken:(NSString *)token completion:(void(^)(NSError *error))completion {
    RLMRealmConfiguration *configuration = [self adminRealmConfigurationForServerURL:url accessToken:token];

    NSError *error;
    self.realm = [RLMRealm realmWithConfiguration:configuration error:&error];

    if (error != nil) {
        if (completion) {
            completion(error);
        }

        return NSModalResponseAbort;
    }

    __weak typeof(self) weekSelf = self;
    self.notificationToken = [self.realm addNotificationBlock:^(RLMNotification  _Nonnull notification, RLMRealm * _Nonnull realm) {
        [weekSelf.tableView reloadData];
    }];

    self.window.title = url.host;

    return [NSApp runModalForWindow:self.window];
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

#pragma mark - NSTableViewDelegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    self.selectedRealmPath = self.tableView.selectedRow > 0 ? @"REALM_PATH" : nil;
}

@end

