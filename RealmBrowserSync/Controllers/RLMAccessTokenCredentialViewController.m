//
//  RLMAccessTokenCredentialViewController.m
//  RealmBrowser
//
//  Created by Dmitry Obukhov on 31/08/16.
//  Copyright © 2016 Realm inc. All rights reserved.
//

#import "RLMAccessTokenCredentialViewController.h"

@interface RLMAccessTokenCredentialViewController () <NSTextFieldDelegate>

@property (nonatomic, weak) IBOutlet NSTextField *tokenTextField;

@end

@implementation RLMAccessTokenCredentialViewController

- (NSString *)title {
    return @"Access Token";
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tokenTextField.delegate = self;
}

- (RLMSyncCredential *)credential {
    NSString *token = self.tokenTextField.stringValue;

    if (token.length > 0) {
        // FIXME: RLMIdentityProviderRealm is used for RLMIdentityProviderAccessToken currently
        return [[RLMSyncCredential alloc] initWithCustomToken:token provider:RLMIdentityProviderRealm userInfo:nil];
    }

    return nil;
}

- (void)setCredential:(RLMSyncCredential *)credential {
    self.tokenTextField.stringValue = credential.token;
}

#pragma mark - NSTextFieldDelegate

- (void)controlTextDidChange:(NSNotification *)obj {
    // Trigger KVO notification for credential
    [self willChangeValueForKey:@"credential"];
    [self didChangeValueForKey:@"credential"];
}

@end
