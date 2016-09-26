//
//  RLMOpenSyncURLWindowController.h
//  RealmBrowser
//
//  Created by Dmitry Obukhov on 16/08/16.
//  Copyright © 2016 Realm inc. All rights reserved.
//

@import Realm;

#import "RLMWindowController.h"

@interface RLMOpenSyncURLWindowController : RLMWindowController

@property (nonatomic, copy) NSURL *url;
@property (nonatomic, strong, readonly) RLMSyncCredential *credential;

@end
