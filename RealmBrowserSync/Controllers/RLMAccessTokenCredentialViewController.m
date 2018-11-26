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

#import "RLMAccessTokenCredentialViewController.h"
#import "RLMCredentialViewController+Private.h"

@interface RLMAccessTokenCredentialViewController ()

@property (nonatomic, weak) IBOutlet NSTextField *tokenTextField;

@end

@implementation RLMAccessTokenCredentialViewController

- (NSString *)title {
    return @"Access Token";
}

- (NSArray *)textFieldsForCredentials {
    return @[self.tokenTextField];
}

- (RLMSyncCredentials *)credentials {
    NSString *token = self.tokenTextField.stringValue;

    if (token.length > 0) {
        // FIXME: remove after it's possible to pass nil identity to create credential
        NSString *identity = [NSUUID UUID].UUIDString;

        return [RLMSyncCredentials credentialsWithAccessToken:token identity:identity];
    }

    return nil;
}

- (void)setCredentials:(RLMSyncCredentials *)credentials {
    self.tokenTextField.stringValue = credentials.token;
}

@end
