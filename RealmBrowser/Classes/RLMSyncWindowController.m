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

#import "RLMSyncWindowController.h"

@interface RLMSyncWindowController () <NSTextFieldDelegate>

@property (nonatomic, strong) NSURL *realmFilePath;

@property (strong, nonatomic, readwrite) NSString *serverURL;
@property (strong, nonatomic, readwrite) NSString *serverIdentity;

- (BOOL)testSyncCredentialsWithURL:(NSString *)url identity:(NSString *)identity;

@end

@implementation RLMSyncWindowController

- (instancetype)initWithRealmFilePath:(NSURL *)realmFilePath
{
    if (self = [super initWithWindowNibName:@"SyncWindow"]) {
        _realmFilePath = realmFilePath;
    }
    
    return self;
}

- (void)controlTextDidChange:(NSNotification *)notification {
    NSString *serverURL = self.urlTextField.stringValue;
    NSString *identity = self.identityTextField.stringValue;
    
    self.okayButton.enabled = (serverURL.length > 0 && identity.length > 0);
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
    
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
}

- (IBAction)cancelButtonClicked:(id)sender
{
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
}

- (BOOL)testSyncCredentialsWithURL:(NSString *)url identity:(NSString *)identity
{
    RLMRealmConfiguration *configuration = [[RLMRealmConfiguration alloc] init];
    configuration.path = self.realmFilePath.path;
    configuration.dynamic = YES;
    configuration.customSchema = nil;
    configuration.syncIdentity = identity;
    configuration.syncServerURL = [NSURL URLWithString:url];
    
    NSError *error = nil;
    @autoreleasepool {
        [RLMRealm realmWithConfiguration:configuration error:&error];
    }
    
    return (error == nil);
}

@end
