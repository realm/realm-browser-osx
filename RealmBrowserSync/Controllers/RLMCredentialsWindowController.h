//
//  RLMCredentialsWindowController.h
//  RealmBrowser
//
//  Created by Dmitry Obukhov on 29/08/16.
//  Copyright © 2016 Realm inc. All rights reserved.
//

@import Realm;

#import "RLMWindowController.h"

@interface RLMCredentialsWindowController : RLMWindowController

@property (nonatomic, strong) NSString *message;
@property (nonatomic, strong) RLMCredential *credential;

- (instancetype)initWithSyncURL:(NSURL *)syncURL;

@end
