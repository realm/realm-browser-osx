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

#import "RLMGoogleCredentialViewController.h"
#import "RLMCredentialViewController+Private.h"

@interface RLMGoogleCredentialViewController ()

@property (nonatomic, weak) IBOutlet NSTextField *tokenTextField;

@end

@implementation RLMGoogleCredentialViewController

- (NSString *)title {
    return @"Google";
}

- (NSArray *)textFieldsForCredential {
    return @[self.tokenTextField];
}

- (RLMSyncCredential *)credential {
    NSString *token = self.tokenTextField.stringValue;

    if (token.length > 0) {
        return [[RLMSyncCredential alloc] initWithCustomToken:token provider:RLMIdentityProviderGoogle userInfo:nil];
    }

    return nil;
}

- (void)setCredential:(RLMSyncCredential *)credential {
    self.tokenTextField.stringValue = credential.token;
}

@end
