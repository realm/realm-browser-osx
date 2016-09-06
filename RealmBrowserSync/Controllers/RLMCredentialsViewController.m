//
//  RLMCredentialsViewController.m
//  RealmBrowser
//
//  Created by Dmitry Obukhov on 31/08/16.
//  Copyright © 2016 Realm inc. All rights reserved.
//

#import "RLMCredentialsViewController.h"

#import "RLMUsernameCredentialViewController.h"
#import "RLMFacebookCredentialViewController.h"
#import "RLMGoogleCredentialViewController.h"
#import "RLMAccessTokenCredentialViewController.h"

@interface RLMCredentialsViewController ()

@property (nonatomic, weak) IBOutlet NSTabView *tabView;

@property (nonatomic, strong) NSURL *serverURL;

@end

@implementation RLMCredentialsViewController

+ (NSArray *)supportedIdentityProviders {
    return @[
        RLMIdentityProviderUsernamePassword,
        RLMIdentityProviderFacebook,
        RLMIdentityProviderGoogle,
        RLMIdentityProviderRealm
    ];
}

+ (Class)credentialViewControllerClassForIdentityProvider:(RLMIdentityProvider)provider {
    NSDictionary *classByProvider = @{
        RLMIdentityProviderUsernamePassword: [RLMUsernameCredentialViewController class],
        RLMIdentityProviderFacebook: [RLMFacebookCredentialViewController class],
        RLMIdentityProviderGoogle: [RLMGoogleCredentialViewController class],
        RLMIdentityProviderRealm: [RLMAccessTokenCredentialViewController class],
    };

    return classByProvider[provider];
}

- (instancetype)initWithSyncURL:(NSURL *)syncURL {
    self = [super initWithNibName:@"CredentialsView" bundle:nil];

    if (self != nil) {
        self.serverURL = [[NSURL alloc] initWithString:@"/" relativeToURL:syncURL].absoluteURL;
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

        RLMCredentialViewController *credentialController = [[viewControllerClass alloc] initWithServerURL:self.serverURL credential:self.credential];

        NSTabViewItem *item = [NSTabViewItem tabViewItemWithViewController:credentialController];
        item.identifier = provider;

        [self.tabView addTabViewItem:item];
    }
}

- (RLMCredential *)credential {
    return self.selectedCredentialViewController.credential;
}

- (void)setCredential:(RLMCredential *)credential {
    if (![[self.class supportedIdentityProviders] containsObject:credential.provider]) {
        return;
    }

    // Force load view if it's not loaded yet
    [self view];

    [self.tabView selectTabViewItemWithIdentifier:credential.provider];
    self.selectedCredentialViewController.credential = credential;
}

- (RLMCredentialViewController *)selectedCredentialViewController {
    return (RLMCredentialViewController *)self.tabView.selectedTabViewItem.viewController;
}

@end
