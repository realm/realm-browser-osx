//
//  RLMFacebookCredentialViewController.m
//  RealmBrowser
//
//  Created by Dmitry Obukhov on 05/09/16.
//  Copyright © 2016 Realm inc. All rights reserved.
//

#import "RLMFacebookCredentialViewController.h"

@interface RLMFacebookCredentialViewController ()

@property (nonatomic, weak) IBOutlet NSTextField *tokenTextField;

@end

@implementation RLMFacebookCredentialViewController

- (NSString *)title {
    return @"Facebook";
}

- (RLMCredential *)credential {
    NSString *token = self.tokenTextField.stringValue;

    if (token.length > 0 && self.serverURL != nil) {
        return [RLMCredential credentialWithFacebookToken:token];
    }

    return nil;
}

- (void)setCredential:(RLMCredential *)credential {
    self.tokenTextField.stringValue = credential.credentialToken;
}

@end
