//
//  RLMWelcomeWindowController.m
//  RealmBrowser
//
//  Created by Dmitry Obukhov on 02/09/16.
//  Copyright © 2016 Realm inc. All rights reserved.
//

#import "RLMWelcomeWindowController.h"
#import "RLMApplicationDelegate.h"

@interface RLMWelcomeWindowController ()

@end

@implementation RLMWelcomeWindowController

- (IBAction)openRealmFile:(id)sender {
    [self close];
    [[NSDocumentController sharedDocumentController] openDocument:sender];
}

- (IBAction)openRealmURL:(id)sender {
    [self close];
    [(RLMApplicationDelegate *)NSApp.delegate openSyncURL:sender];
}

- (IBAction)connecToServer:(id)sender {
    [self close];
    [(RLMApplicationDelegate *)NSApp.delegate connectToSyncServer:sender];
}

@end
