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

- (RLMSyncCredential *)credential {
    NSString *token = self.tokenTextField.stringValue;

    if (token.length > 0) {
        return [RLMSyncCredential credentialWithFacebookToken:token];
    }

    return nil;
}

- (void)setCredential:(RLMSyncCredential *)credential {
    self.tokenTextField.stringValue = credential.token;
}

@end
