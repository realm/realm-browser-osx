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

RLMIdentityProvider const RLMIdentityProviderAccessToken = @"accessToken";

@interface RLMCredentialsViewController ()<NSTabViewDelegate>

@property (nonatomic, weak) IBOutlet NSTabView *tabView;

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

- (instancetype)init {
    return [super initWithNibName:@"CredentialsView" bundle:nil];
}

- (void)dealloc {
    [self.selectedCredentialViewController removeObserver:self forKeyPath:@"credentials"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tabView.delegate = self;
    [self reloadCredentialViews];
}

- (void)reloadCredentialViews {
    for (NSTabViewItem *item in self.tabView.tabViewItems) {
        [self.tabView removeTabViewItem:item];
    }

    for (RLMIdentityProvider provider in [self.class supportedIdentityProviders]) {
        if ([self.delegate respondsToSelector:@selector(credentialsViewController:shoudShowCredentialsViewForIdentityProvider:)]) {
            if (![self.delegate credentialsViewController:self shoudShowCredentialsViewForIdentityProvider:provider]) {
                continue;
            }
        }

        Class viewControllerClass = [self.class credentialViewControllerClassForIdentityProvider:provider];

        RLMCredentialViewController *credentialController = [[viewControllerClass alloc] init];

        NSTabViewItem *item = [NSTabViewItem tabViewItemWithViewController:credentialController];
        item.identifier = provider;

        if ([self.delegate respondsToSelector:@selector(credentialsViewController:labelForIdentityProvider:)]) {
            item.label = [self.delegate credentialsViewController:self labelForIdentityProvider:provider] ?: item.label;
        }

        [self.tabView addTabViewItem:item];
    }
}

- (RLMSyncCredentials *)credentials {
    return self.selectedCredentialViewController.credentials;
}

- (void)setCredentials:(RLMSyncCredentials *)credentials {
    if (![[self.class supportedIdentityProviders] containsObject:credentials.provider]) {
        return;
    }

    // Force load view if it's not loaded yet
    [self view];

    [self.tabView selectTabViewItemWithIdentifier:credentials.provider];
    [self.view layoutSubtreeIfNeeded];

    self.selectedCredentialViewController.credentials = credentials;
}

- (RLMCredentialViewController *)selectedCredentialViewController {
    return (RLMCredentialViewController *)self.tabView.selectedTabViewItem.viewController;
}

#pragma mark - NSTabViewDelegate

- (void)tabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem {
    [self.selectedCredentialViewController removeObserver:self forKeyPath:@"credentials"];
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
    [self.selectedCredentialViewController addObserver:self forKeyPath:@"credentials" options:NSKeyValueObservingOptionInitial context:nil];
}

#pragma make - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (object == self.selectedCredentialViewController) {
        if ([self.delegate respondsToSelector:@selector(credentialsViewControllerDidChangeCredentials:)]) {
            [self.delegate credentialsViewControllerDidChangeCredentials:self];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
