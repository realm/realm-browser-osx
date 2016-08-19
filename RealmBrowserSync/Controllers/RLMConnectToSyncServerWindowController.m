//
//  RLMConnectToSyncServerWindowController.m
//  RealmBrowser
//
//  Created by Dmitry Obukhov on 16/08/16.
//  Copyright © 2016 Realm inc. All rights reserved.
//

#import "RLMConnectToSyncServerWindowController.h"
#import "RLMSyncCredentialsWindowController+Private.h"

@interface RLMConnectToSyncServerWindowController ()

@end

@implementation RLMConnectToSyncServerWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    self.window.title = @"Connect to Object Server";
    self.urlLabel.stringValue = @"Object Server Address";
    self.tokenLabel.stringValue = @"Admin Access Token";
    self.okButton.title = @"Connect";
}

- (BOOL)validateCredentials:(NSError *__autoreleasing *)error {
    BOOL result = [super validateCredentials:error];

    if (result) {
        // FIXME: report error here
        result = self.url.path.length < 1 && self.token.length > 0;
    }

    return result;
}

@end
