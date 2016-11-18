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
#import "RLMCredentialViewController+Private.h"

@interface RLMUsernameCredentialViewController ()

@property (nonatomic, weak) IBOutlet NSTextField *usernameTextField;
@property (nonatomic, weak) IBOutlet NSTextField *passwordTextField;

@end

@implementation RLMUsernameCredentialViewController

- (NSString *)title {
    return @"Username";
}

- (NSArray *)textFieldsForCredentials {
    return @[self.usernameTextField, self.passwordTextField];
}

- (RLMSyncCredentials *)credentials {
    NSString *username = self.usernameTextField.stringValue;
    NSString *password = self.passwordTextField.stringValue;

    if (username.length > 0 && password.length > 0) {
        return [RLMSyncCredentials credentialsWithUsername:username password:password register:NO];
    }

    return nil;
}

- (void)setCredentials:(RLMSyncCredentials *)credentials {
    self.usernameTextField.stringValue = credentials.token;
}

@end
