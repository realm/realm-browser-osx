//
//  RLMSyncCredentialsWindowController.m
//  RealmBrowser
//
//  Created by Dmitry Obukhov on 16/08/16.
//  Copyright © 2016 Realm inc. All rights reserved.
//

#import "RLMSyncCredentialsWindowController.h"
#import "RLMSyncCredentialsWindowController+Private.h"

static NSString * const urlKey = @"URL";
static NSString * const tokenKey = @"Token";

NSString * const RLMSyncCredentialsWindowControllerErrorDomain = @"io.realm.realmbrowser.sync-credentials-window";

@implementation RLMSyncCredentialsWindowController

- (instancetype)init {
    return [super initWithWindowNibName:@"SyncCredentialsWindow"];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    if (self.url == nil && self.token == nil) {
        [self loadRecentCredentials];
    }
}

- (BOOL)validateCredentials:(NSError *__autoreleasing *)error {
    __autoreleasing NSError *localError;
    if (error == nil) {
        error = &localError;
    }

    if (!([self.url.scheme isEqualToString:@"realm"] && self.url.host.length > 0)) {
        *error = [self errorWithCode:0 description:@"Invalid Object Server URL" recoverySuggestion:@"Provide a valid URL"];
        return NO;
    }

    if (self.token != nil && [self.token componentsSeparatedByString:@":"].count != 2) {
        *error = [self errorWithCode:1 description:@"Invalid Access Token" recoverySuggestion:@"Provide a valid Access Token in format:\n \"IDENTITY:SIGNATURE\" or leave it empty."];
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

- (void)setToken:(NSString *)token {
    if ([token isEqualToString:self.token]) {
        return;
    }

    _token = [token copy];

    [self updateUI];
}

- (void)updateUI {
    self.okButton.enabled = [self validateCredentials:nil];
}

- (NSModalResponse)runModal {
    [self.window center];
    return [NSApp runModalForWindow:self.window];
}

#pragma mark - Actions

- (IBAction)okButtonClicked:(id)sender {
    [self.window makeFirstResponder:nil];

    [self seaveRecentCredentials];
    [self close];
    [NSApp stopModalWithCode:NSModalResponseOK];
}

- (IBAction)cancelButtonClicked:(id)sender {
    [self close];
    [NSApp stopModalWithCode:NSModalResponseCancel];
}

#pragma mark - NSWindowDelegate

- (BOOL)windowShouldClose:(id)sender {
    [NSApp stopModalWithCode:NSModalResponseCancel];
    return YES;
}

#pragma mark - Private

- (void)loadRecentCredentials {
    self.url = [[NSUserDefaults standardUserDefaults] URLForKey:[self prefixedUserDefaultsKeyForKey:urlKey]];
    self.token = [[NSUserDefaults standardUserDefaults] stringForKey:[self prefixedUserDefaultsKeyForKey:tokenKey]];
}

- (void)seaveRecentCredentials {
    [[NSUserDefaults standardUserDefaults] setURL:self.url forKey:[self prefixedUserDefaultsKeyForKey:urlKey]];
    [[NSUserDefaults standardUserDefaults] setObject:self.token forKey:[self prefixedUserDefaultsKeyForKey:tokenKey]];
}

- (NSString *)prefixedUserDefaultsKeyForKey:(NSString *)key {
    return [self.className stringByAppendingString:key];
}

- (NSError *)errorWithCode:(NSInteger)code description:(NSString *)description recoverySuggestion:(NSString *)recoverySuggestion {
    NSDictionary *userInfo = @{
        NSLocalizedDescriptionKey: description,
        NSLocalizedRecoverySuggestionErrorKey: recoverySuggestion
    };

    return [NSError errorWithDomain:RLMSyncCredentialsWindowControllerErrorDomain code:code userInfo:userInfo];
}

@end

#pragma mark - Value Transformers

@interface RLMSyncServerURLValueTransformer : NSValueTransformer

@end

@implementation RLMSyncServerURLValueTransformer

+ (Class)transformedValueClass {
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (nullable id)transformedValue:(nullable id)value {
    NSURL *url = value;

    return url.absoluteString;
}

- (nullable id)reverseTransformedValue:(nullable id)value {
    return [NSURL URLWithString:value];
}

@end

