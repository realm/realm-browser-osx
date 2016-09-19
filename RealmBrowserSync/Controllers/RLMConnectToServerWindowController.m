//
//  RLMConnectToServerWindowController.m
//  RealmBrowser
//
//  Created by Dmitry Obukhov on 16/08/16.
//  Copyright © 2016 Realm inc. All rights reserved.
//

#import "RLMConnectToServerWindowController.h"
#import "RLMBrowserConstants.h"

static NSString * const serverURLKey = @"ServerURL";
static NSString * const adminAccessTokenKey = @"AdminAccessToken";

NSString * const RLMConnectToServerWindowControllerErrorDomain = @"io.realm.realmbrowser.sync-connect-to-server-window";

@interface RLMConnectToServerWindowController ()

@property (weak) IBOutlet NSTextField *serverURLTextField;
@property (weak) IBOutlet NSTextField *tokenTextField;

@property (weak) IBOutlet NSButton *connectButton;

@end

@implementation RLMConnectToServerWindowController

- (void)windowDidLoad {
    [super windowDidLoad];

    if (self.serverURL == nil && self.adminAccessToken == nil) {
        [self loadRecentCredentials];
    }
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

    if ([self.adminAccessToken componentsSeparatedByString:@":"].count != 2) {
        *error = [self errorWithCode:1 description:@"Invalid Access Token" recoverySuggestion:@"Provide a valid Access Token in format:\n \"IDENTITY:SIGNATURE\" or leave it empty."];
        return NO;
    }

    return YES;
}

- (void)setServerURL:(NSURL *)url {
    if ([url isEqualTo:self.serverURL]) {
        return;
    }

    _serverURL = [url copy];

    [self updateUI];
}

- (void)setAdminAccessToken:(NSString *)token {
    if ([token isEqualToString:self.adminAccessToken]) {
        return;
    }

    _adminAccessToken = [token copy];

    [self updateUI];
}

- (void)updateUI {
    self.connectButton.enabled = [self validateCredentials:nil];
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
    self.adminAccessToken = [[NSUserDefaults standardUserDefaults] stringForKey:adminAccessTokenKey];
}

- (void)seaveRecentCredentials {
    [[NSUserDefaults standardUserDefaults] setURL:self.serverURL forKey:serverURLKey];
    [[NSUserDefaults standardUserDefaults] setObject:self.adminAccessToken forKey:adminAccessTokenKey];
}

- (NSError *)errorWithCode:(NSInteger)code description:(NSString *)description recoverySuggestion:(NSString *)recoverySuggestion {
    NSDictionary *userInfo = @{
        NSLocalizedDescriptionKey: description,
        NSLocalizedRecoverySuggestionErrorKey: recoverySuggestion
    };

    return [NSError errorWithDomain:RLMConnectToServerWindowControllerErrorDomain code:code userInfo:userInfo];
}

@end
