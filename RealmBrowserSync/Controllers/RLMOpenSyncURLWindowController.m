//
//  RLMOpenSyncURLWindowController.m
//  RealmBrowser
//
//  Created by Dmitry Obukhov on 16/08/16.
//  Copyright © 2016 Realm inc. All rights reserved.
//

#import "RLMOpenSyncURLWindowController.h"
#import "RLMCredentialsViewController.h"
#import "NSView+RLMExtensions.h"

static NSString * const urlKey = @"URL";

NSString * const RLMOpenSyncURLWindowControllerErrorDomain = @"io.realm.realmbrowser.sync-open-sync-url-window";

@interface RLMOpenSyncURLWindowController ()

@property (nonatomic, weak) IBOutlet NSTextField *urlTextField;
@property (nonatomic, weak) IBOutlet NSView *credentialsContainerView;

@property (nonatomic, weak) IBOutlet NSButton *openButton;

@property (nonatomic, strong) RLMCredentialsViewController *credentialsViewController;

@end

@implementation RLMOpenSyncURLWindowController

- (void)windowDidLoad {
    [super windowDidLoad];

    if (self.url == nil) {
        [self loadRecentCredentials];
    }

    // TODO: use recent credentials for credentialsViewController
    self.credentialsViewController = [[RLMCredentialsViewController alloc] initWithSyncURL:self.url authServerURL:nil];

    [self.credentialsContainerView addContentSubview:self.credentialsViewController.view];
}

- (BOOL)validateCredentials:(NSError *__autoreleasing *)error {
    __autoreleasing NSError *localError;
    if (error == nil) {
        error = &localError;
    }

    if (!([self.url.scheme isEqualToString:@"realm"] && self.url.host.length > 0 && self.url.path.length > 1)) {
        *error = [self errorWithCode:0 description:@"Invalid Object Server URL" recoverySuggestion:@"Provide a valid URL"];
        return NO;
    }

    return YES;
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

- (NSURL *)authServerURL {
    return self.credentialsViewController.authServerURL;
}

- (void)updateUI {
    self.openButton.enabled = [self validateCredentials:nil];
}

#pragma mark - Actions

- (IBAction)open:(id)sender {
    [self seaveRecentCredentials];
    [self closeWithReturnCode:NSModalResponseOK];
}

- (IBAction)cancel:(id)sender {
    [self closeWithReturnCode:NSModalResponseCancel];
}

#pragma mark - Private

- (void)loadRecentCredentials {
    self.url = [[NSUserDefaults standardUserDefaults] URLForKey:urlKey];
}

- (void)seaveRecentCredentials {
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
