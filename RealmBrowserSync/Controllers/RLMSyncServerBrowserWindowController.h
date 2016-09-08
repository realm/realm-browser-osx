//
//  RLMSyncServerBrowserWindowController.h
//  RealmBrowser
//
//  Created by Dmitry Obukhov on 11/08/16.
//  Copyright © 2016 Realm inc. All rights reserved.
//

@import Realm;

#import "RLMWindowController.h"

@interface RLMSyncServerBrowserWindowController : RLMWindowController

@property (nonatomic, readonly) NSURL *selectedURL;

- (instancetype)initWithServerURL:(NSURL *)serverURL user:(RLMSyncUser *)user;

@end
