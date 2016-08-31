//
//  RLMConnectToServerWindowController.h
//  RealmBrowser
//
//  Created by Dmitry Obukhov on 16/08/16.
//  Copyright © 2016 Realm inc. All rights reserved.
//

#import "RLMWindowController.h"

@interface RLMConnectToServerWindowController : RLMWindowController

@property (nonatomic, copy) NSURL *serverURL;
@property (nonatomic, copy) NSString *adminAccessToken;

@end
