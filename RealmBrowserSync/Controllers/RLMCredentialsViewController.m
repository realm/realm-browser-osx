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

#import "RLMCredentialsViewController.h"

#import "RLMUsernameCredentialViewController.h"
#import "RLMFacebookCredentialViewController.h"
#import "RLMGoogleCredentialViewController.h"
#import "RLMCloudKitCredentialViewController.h"
#import "RLMAccessTokenCredentialViewController.h"

@interface RLMCredentialsViewController ()

@property (nonatomic, weak) IBOutlet NSTabView *tabView;

@property (nonatomic, strong) NSURL *authServerURL;

@end

@implementation RLMCredentialsViewController

+ (NSArray *)supportedIdentityProviders {
    return @[
        RLMIdentityProviderUsernamePassword,
        RLMIdentityProviderFacebook,
        RLMIdentityProviderGoogle,
        RLMIdentityProviderICloud,
        @"accessToken"
    ];
}

+ (Class)credentialViewControllerClassForIdentityProvider:(RLMIdentityProvider)provider {
    NSDictionary *classByProvider = @{
        RLMIdentityProviderUsernamePassword: [RLMUsernameCredentialViewController class],
        RLMIdentityProviderFacebook: [RLMFacebookCredentialViewController class],
        RLMIdentityProviderGoogle: [RLMGoogleCredentialViewController class],
        RLMIdentityProviderICloud: [RLMCloudKitCredentialViewController class],
        @"accessToken": [RLMAccessTokenCredentialViewController class],
    };

    return classByProvider[provider];
}

- (instancetype)initWithSyncURL:(NSURL *)syncURL authServerURL:(NSURL *)authServerURL {
    self = [super initWithNibName:@"CredentialsView" bundle:nil];

    if (self != nil) {
        self.authServerURL = authServerURL ?: [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:8080", syncURL.host]];
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    for (NSTabViewItem *item in self.tabView.tabViewItems) {
        [self.tabView removeTabViewItem:item];
    }

    for (RLMIdentityProvider provider in [self.class supportedIdentityProviders]) {
        Class viewControllerClass = [self.class credentialViewControllerClassForIdentityProvider:provider];

        RLMCredentialViewController *credentialController = [[viewControllerClass alloc] init];

        NSTabViewItem *item = [NSTabViewItem tabViewItemWithViewController:credentialController];
        item.identifier = provider;

        [self.tabView addTabViewItem:item];
    }
}

- (RLMSyncCredential *)credential {
    return self.selectedCredentialViewController.credential;
}

- (void)setCredential:(RLMSyncCredential *)credential {
    if (![[self.class supportedIdentityProviders] containsObject:credential.provider]) {
        return;
    }

    // Force load view if it's not loaded yet
    [self view];

    [self.tabView selectTabViewItemWithIdentifier:credential.provider];
    [self.view layoutSubtreeIfNeeded];

    self.selectedCredentialViewController.credential = credential;
}

- (RLMCredentialViewController *)selectedCredentialViewController {
    return (RLMCredentialViewController *)self.tabView.selectedTabViewItem.viewController;
}

@end
