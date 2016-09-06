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

- (RLMCredential *)credential {
    NSString *token = self.tokenTextField.stringValue;

    if (token.length > 0 && self.serverURL != nil) {
        return [[RLMCredential alloc] initWithCredentialToken:token provider:RLMIdentityProviderGoogle userInfo:nil serverURL:self.serverURL];
    }

    return nil;
}

- (void)setCredential:(RLMCredential *)credential {
    self.tokenTextField.stringValue = credential.credentialToken;
}

@end
