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
@import Realm.Dynamic;
@import Realm.Private;

NSString * const kSyncServerURLKey = @"SyncServerURL";
NSString * const kSyncIdentityKey = @"SyncIdentity";

#import "RLMSyncWindowController.h"

@interface RLMSyncWindowController () <NSTextFieldDelegate>

@property (nonatomic, strong, readwrite) NSString *realmFilePath;

@property (strong, nonatomic, readwrite) NSString *serverURL;
@property (strong, nonatomic, readwrite) NSString *serverIdentity;

- (BOOL)testSyncCredentialsWithURL:(NSString *)url identity:(NSString *)identity;

@end

@implementation RLMSyncWindowController

- (instancetype)initWithTempRealmFile
{
    if (self = [super initWithWindowNibName:@"SyncWindow"]) {
        NSString *tempFileName = [NSString stringWithFormat:@"%@.realm", [NSUUID UUID].UUIDString];
        _realmFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:tempFileName];
    }
    
    return self;
}

- (instancetype)initWithRealmFilePath:(NSURL *)realmFilePath
{
    if (self = [super initWithWindowNibName:@"SyncWindow"]) {
        _realmFilePath = realmFilePath.path;
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *serverURL = [defaults stringForKey:kSyncServerURLKey];
    if (serverURL.length > 0) {
        self.urlTextField.stringValue = serverURL;
    }
    
    NSString *identity = [defaults stringForKey:kSyncIdentityKey];
    if (identity.length > 0) {
        self.identityTextField.stringValue = identity;
    }
    
    if (serverURL.length > 0 && identity.length > 0) {
        self.okayButton.enabled = YES;
    }
}

- (void)controlTextDidChange:(NSNotification *)notification {
    NSString *serverURL = self.urlTextField.stringValue;
    self.okayButton.enabled = (serverURL.length > 0);
}

- (IBAction)okayButtonClicked:(id)sender
{
    NSString *serverURL = self.urlTextField.stringValue;
    NSString *serverIdentity = self.identityTextField.stringValue;
    
    if ([self testSyncCredentialsWithURL:serverURL identity:serverIdentity] == NO) {
        self.errorTextField.hidden = NO;
        return;
    }
    
    self.serverURL = serverURL;
    self.serverIdentity = serverIdentity;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:serverURL forKey:kSyncServerURLKey];
    [defaults setObject:serverIdentity forKey:kSyncIdentityKey];
    [defaults synchronize];
    
    if (self.window.sheetParent) {
        [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
        return;
    }
    
    if (self.OKButtonClickedHandler) {
        self.OKButtonClickedHandler();
    }
    
    [self close];
    if (self.windowClosedHandler) {
        self.windowClosedHandler();
    }
}

- (IBAction)cancelButtonClicked:(id)sender
{
    if (self.window.sheetParent) {
        [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
        return;
    }
    
    [self close];
    if (self.windowClosedHandler) {
        self.windowClosedHandler();
    }
}

- (BOOL)testSyncCredentialsWithURL:(NSString *)url identity:(NSString *)identity
{
    RLMRealmConfiguration *configuration = [[RLMRealmConfiguration alloc] init];
    configuration.path = self.realmFilePath;
    configuration.dynamic = YES;
    configuration.customSchema = nil;
    configuration.syncServerURL = [NSURL URLWithString:url];
    
    if (identity.length == 40) {
        configuration.syncIdentity = identity;
    }
        
    NSError *error = nil;
    BOOL realmCreated = NO;
    @autoreleasepool {
        RLMRealm *realm = [RLMRealm realmWithConfiguration:configuration error:&error];
        realmCreated = (realm != nil);
    }
    
    return (error == nil);
}

@end
