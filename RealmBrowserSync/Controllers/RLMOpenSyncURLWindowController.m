//
//  RLMOpenSyncURLWindowController.m
//  RealmBrowser
//
//  Created by Dmitry Obukhov on 16/08/16.
//  Copyright © 2016 Realm inc. All rights reserved.
//

#import "RLMOpenSyncURLWindowController.h"
#import "RLMSyncCredentialsWindowController+Private.h"

@interface RLMOpenSyncURLWindowController ()

@end

@implementation RLMOpenSyncURLWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    self.window.title = @"Open Sync URL";
    self.urlLabel.stringValue = @"Sync URL";
    self.tokenLabel.stringValue = @"Access Token";
    self.okButton.title = @"Open";
}

- (BOOL)validateCredentials:(NSError *__autoreleasing *)error {
    BOOL result = [super validateCredentials:error];

    if (result) {
        // FIXME: report error here
        result = self.url.path.length > 1;
    }

    return result;
}

@end
