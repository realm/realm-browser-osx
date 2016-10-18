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

#import "RLMOpenSyncURLWindowController.h"
#import "RLMCredentialsViewController.h"
#import "NSView+RLMExtensions.h"
#import "RLMBrowserConstants.h"

static NSString * const urlKey = @"URL";

NSString * const RLMOpenSyncURLWindowControllerErrorDomain = @"io.realm.realmbrowser.sync-open-sync-url-window";

@interface RLMOpenSyncURLWindowController ()<RLMCredentialsViewControllerDelegate>

@property (nonatomic, weak) IBOutlet NSTextField *urlTextField;
@property (nonatomic, weak) IBOutlet NSView *credentialsContainerView;

@property (nonatomic, weak) IBOutlet NSButton *openButton;

@property (nonatomic, strong) RLMCredentialsViewController *credentialsViewController;

@end

@implementation RLMOpenSyncURLWindowController

- (void)windowDidLoad {
    [super windowDidLoad];

    if (self.url == nil) {
        [self loadRecentURL];
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

    if (!(([self.url.scheme isEqualToString:kRealmURLScheme] || [self.url.scheme isEqualToString:kSecureRealmURLScheme]) && self.url.host.length > 0 && self.url.path.length > 1)) {
        *error = [self errorWithCode:0 description:@"Invalid Object Server URL" recoverySuggestion:@"Provide a valid URL"];
        return NO;
    }

    return self.credential != nil;
}

- (void)setUrl:(NSURL *)url {
    if ([url isEqualTo:self.url]) {
        return;
    }

    _url = [url copy];

    [self updateUI];
}

- (RLMSyncCredential *)credential {
    return self.credentialsViewController.credential;
}

- (void)updateUI {
    self.openButton.enabled = [self validateCredentials:nil];
}

#pragma mark - Actions

- (IBAction)open:(id)sender {
    [self seaveRecentURL];
    [self closeWithReturnCode:NSModalResponseOK];
}

- (IBAction)cancel:(id)sender {
    [self closeWithReturnCode:NSModalResponseCancel];
}

#pragma mark - RLMCredentialsViewControllerDelegate

- (void)credentialsViewControllerDidChangeCredential:(RLMCredentialsViewController *)controller {
    [self updateUI];
}

#pragma mark - Private

- (void)loadRecentURL {
    self.url = [[NSUserDefaults standardUserDefaults] URLForKey:urlKey];
}

- (void)seaveRecentURL {
    [[NSUserDefaults standardUserDefaults] setURL:self.url forKey:urlKey];
}

- (NSError *)errorWithCode:(NSInteger)code description:(NSString *)description recoverySuggestion:(NSString *)recoverySuggestion {
    NSDictionary *userInfo = @{
        NSLocalizedDescriptionKey: description,
        NSLocalizedRecoverySuggestionErrorKey: recoverySuggestion
    };

    return [NSError errorWithDomain:RLMOpenSyncURLWindowControllerErrorDomain code:code userInfo:userInfo];
}

@end
