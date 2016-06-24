//
//  RLMSyncCredentialsViewController.m
//  RealmBrowser
//
//  Created by Dmitry Obukhov on 13/06/16.
//  Copyright © 2016 Realm inc. All rights reserved.
//

#import "RLMSyncCredentialsViewController.h"

@implementation RLMSyncCredentialsViewController

- (instancetype)init {
    return [super initWithNibName:@"SyncCredentialsView" bundle:[NSBundle bundleForClass:[self class]]];
}

- (void)viewWillAppear {
    [super viewWillAppear];
    
    if (self.syncServerURL == nil && self.signedUserToken == nil) {
        self.syncServerURL = [[NSUserDefaults standardUserDefaults] URLForKey:@"SyncServerURL"];
        self.signedUserToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"SignedUserToken"];
    }
}

- (void)viewWillDisappear {
    [super viewWillDisappear];
    
    if ([self validateCredentials:nil]) {
        [[NSUserDefaults standardUserDefaults] setURL:self.syncServerURL forKey:@"SyncServerURL"];
        [[NSUserDefaults standardUserDefaults] setObject:self.signedUserToken forKey:@"SignedUserToken"];
    }
}

- (BOOL)validateCredentials:(NSError *__autoreleasing *)error {
    if (!([self.syncServerURL.scheme isEqualToString:@"realm"] && self.syncServerURL.host.length > 0 && self.syncServerURL.path.length > 1)) {
        if (error != nil) {
            *error = [NSError errorWithDomain:@"io.realm.browser" code:0 userInfo:@{NSLocalizedDescriptionKey: @"Invalid Sync Server URL", NSLocalizedRecoverySuggestionErrorKey: @"Provide a valid Sync Server URL in format:\n \"realm://HOST:PORT/PATH\"."}];
        }
        
        return NO;
    }
    
    if (self.signedUserToken != nil && [self.signedUserToken componentsSeparatedByString:@":"].count != 2) {
        if (error != nil) {
            *error = [NSError errorWithDomain:@"io.realm.browser" code:0 userInfo:@{NSLocalizedDescriptionKey: @"Invalid Signed User Token", NSLocalizedRecoverySuggestionErrorKey: @"Provide a valid Signed User Token in format:\n \"IDENTITY:SIGNATURE\" or leave it empty."}];
        }
        
        return NO;
    }
    
    return YES;
}

#pragma mark - NSOpenSavePanelDelegate

- (BOOL)panel:(id)sender validateURL:(NSURL *)url error:(NSError **)outError {
    return [self validateCredentials:outError];
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
