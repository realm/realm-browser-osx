//
//  RLMOpenSyncURLWindowController.h
//  RealmBrowser
//
//  Created by Dmitry Obukhov on 15/06/16.
//  Copyright © 2016 Realm inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RLMSyncCredentialsViewController.h"

@interface RLMSyncServerConnectionWindowController : NSWindowController

@property (strong) RLMSyncCredentialsViewController *credentialsViewController;

- (NSModalResponse)runModal;

@end
