//
//  RLMCloudKitCredentialViewController.m
//  RealmBrowser
//
//  Created by Dmitry Obukhov on 21/09/16.
//  Copyright © 2016 Realm inc. All rights reserved.
//

#import "RLMCloudKitCredentialViewController.h"

@interface RLMCloudKitCredentialViewController ()

@property (nonatomic, weak) IBOutlet NSTextField *tokenTextField;

@end

@implementation RLMCloudKitCredentialViewController

- (NSString *)title {
    return @"CloudKit";
}

- (RLMSyncCredential *)credential {
    NSString *token = self.tokenTextField.stringValue;

    if (token.length > 0) {
        return [[RLMSyncCredential alloc] initWithCustomToken:token provider:RLMIdentityProviderICloud userInfo:nil];
    }

    return nil;
}

- (void)setCredential:(RLMSyncCredential *)credential {
    self.tokenTextField.stringValue = credential.token;
}

@end
