//
//  RLMUsernameCredentialViewController.m
//  RealmBrowser
//
//  Created by Dmitry Obukhov on 31/08/16.
//  Copyright © 2016 Realm inc. All rights reserved.
//

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

- (RLMCredential *)credential {
    NSString *username = self.usernameTextField.stringValue;
    NSString *password = self.passwordTextField.stringValue;

    if (username.length > 0 && password.length) {
        return [[RLMCredential alloc] initWithCredentialToken:username provider:RLMIdentityProviderUsernamePassword userInfo:@{@"password": password, @"register": @(NO)} serverURL:self.serverURL];
    }

    return nil;
}

- (void)setCredential:(RLMCredential *)credential {
    self.usernameTextField.stringValue = credential.credentialToken;
}

#pragma mark - NSTextFieldDelegate

- (void)controlTextDidChange:(NSNotification *)obj {
    // Trigger KVO notification for credential
    [self willChangeValueForKey:@"credential"];
    [self didChangeValueForKey:@"credential"];
}

@end
