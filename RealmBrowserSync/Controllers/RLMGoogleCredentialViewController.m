//
//  RLMGoogleCredentialViewController.m
//  RealmBrowser
//
//  Created by Dmitry Obukhov on 06/09/16.
//  Copyright © 2016 Realm inc. All rights reserved.
//

#import "RLMGoogleCredentialViewController.h"

@interface RLMGoogleCredentialViewController ()

@property (nonatomic, weak) IBOutlet NSTextField *tokenTextField;

@end

@implementation RLMGoogleCredentialViewController

- (NSString *)title {
    return @"Google";
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
