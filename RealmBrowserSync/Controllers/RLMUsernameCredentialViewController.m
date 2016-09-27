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

#import "RLMUsernameCredentialViewController.h"

@interface RLMUsernameCredentialViewController () <NSTextFieldDelegate>

@property (nonatomic, weak) IBOutlet NSTextField *usernameTextField;
@property (nonatomic, weak) IBOutlet NSTextField *passwordTextField;

@end

@implementation RLMUsernameCredentialViewController

- (NSString *)title {
    return @"Username";
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.usernameTextField.delegate = self;
    self.passwordTextField.delegate = self;
}

- (RLMSyncCredential *)credential {
    NSString *username = self.usernameTextField.stringValue;
    NSString *password = self.passwordTextField.stringValue;

    if (username.length > 0 && password.length > 0) {
        return [RLMSyncCredential credentialWithUsername:username password:password actions:RLMAuthenticationActionsUseExistingAccount];
    }

    return nil;
}

- (void)setCredential:(RLMSyncCredential *)credential {
    self.usernameTextField.stringValue = credential.token;
}

#pragma mark - NSTextFieldDelegate

- (void)controlTextDidChange:(NSNotification *)obj {
    // Trigger KVO notification for credential
    [self willChangeValueForKey:@"credential"];
    [self didChangeValueForKey:@"credential"];
}

@end
