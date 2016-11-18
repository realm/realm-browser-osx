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

#import "RLMBrowserConstants.h"
#import "RLMConnectToServerWindowController.h"
#import "RLMCredentialsViewController.h"
#import "NSView+RLMExtensions.h"

static NSString * const serverURLKey = @"ServerURL";
static NSString * const adminAccessTokenKey = @"AdminAccessToken";

NSString * const RLMConnectToServerWindowControllerErrorDomain = @"io.realm.realmbrowser.sync-connect-to-server-window";

@interface RLMConnectToServerWindowController ()<RLMCredentialsViewControllerDelegate>

@property (nonatomic, weak) IBOutlet NSView *credentialsContainerView;
@property (nonatomic, weak) IBOutlet NSTextField *serverURLTextField;
@property (nonatomic, weak) IBOutlet NSTextField *tokenTextField;
@property (nonatomic, weak) IBOutlet NSButton *connectButton;

@property (nonatomic, strong) RLMCredentialsViewController *credentialsViewController;

@end

@implementation RLMConnectToServerWindowController

- (void)windowDidLoad {
    [super windowDidLoad];

    if (self.serverURL == nil && self.credentials == nil) {
        [self loadRecentCredentials];
    }

    self.credentialsViewController = [[RLMCredentialsViewController alloc] init];
    self.credentialsViewController.delegate = self;

    [self.credentialsContainerView addContentSubview:self.credentialsViewController.view];
}

- (BOOL)validateCredentials:(NSError *__autoreleasing *)error {
    __autoreleasing NSError *localError;
    if (error == nil) {
        error = &localError;
    }

    if (!(([self.serverURL.scheme isEqualToString:kRealmURLScheme] || [self.serverURL.scheme isEqualToString:kSecureRealmURLScheme]) && self.serverURL.host.length > 0 && self.serverURL.path.length < 2)) {
        *error = [self errorWithCode:0 description:@"Invalid Object Server URL" recoverySuggestion:@"Provide a valid URL"];
        return NO;
    }

    return self.credentials != nil;
}

- (void)setServerURL:(NSURL *)url {
    if ([url isEqualTo:self.serverURL]) {
        return;
    }

    _serverURL = [url copy];

    [self updateUI];
}

- (RLMSyncCredentials *)credentials {
    return self.credentialsViewController.credentials;
}

- (void)setCredentials:(RLMSyncCredentials *)credentials {
    self.credentialsViewController.credentials = credentials;

    [self updateUI];
}

- (void)updateUI {
    self.connectButton.enabled = [self validateCredentials:nil];
}

#pragma mark - RLMCredentialsViewControllerDelegate

- (BOOL)credentialsViewController:(RLMCredentialsViewController *)controller shoudShowCredentialViewForIdentityProvider:(RLMIdentityProvider)provider {
    return provider == RLMIdentityProviderAccessToken || provider == RLMIdentityProviderUsernamePassword;
}

- (NSString *)credentialsViewController:(RLMCredentialsViewController *)controller labelForIdentityProvider:(RLMIdentityProvider)provider {
    if (provider == RLMIdentityProviderAccessToken) {
        return @"Admin Access Token";
    } else if (provider == RLMIdentityProviderUsernamePassword) {
        return @"Admin Username";
    }

    return nil;
}

- (void)credentialsViewControllerDidChangeCredential:(RLMCredentialsViewController *)controller {
    [self updateUI];
}

#pragma mark - Actions

- (IBAction)connect:(id)sender {
    [self seaveRecentCredentials];

    [self closeWithReturnCode:NSModalResponseOK];
}

- (IBAction)cancel:(id)sender {
    [self closeWithReturnCode:NSModalResponseCancel];
}

#pragma mark - Private

- (void)loadRecentCredentials {
    self.serverURL = [[NSUserDefaults standardUserDefaults] URLForKey:serverURLKey];
}

- (void)seaveRecentCredentials {
    [[NSUserDefaults standardUserDefaults] setURL:self.serverURL forKey:serverURLKey];
}

- (NSError *)errorWithCode:(NSInteger)code description:(NSString *)description recoverySuggestion:(NSString *)recoverySuggestion {
    NSDictionary *userInfo = @{
        NSLocalizedDescriptionKey: description,
        NSLocalizedRecoverySuggestionErrorKey: recoverySuggestion
    };

    return [NSError errorWithDomain:RLMConnectToServerWindowControllerErrorDomain code:code userInfo:userInfo];
}

@end
