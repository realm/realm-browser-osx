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

@property (nonatomic, copy) NSString *message;
@property (nonatomic, strong) RLMSyncCredential *credential;
@property (nonatomic, copy, readonly) NSURL *authServerURL;

- (instancetype)initWithSyncURL:(NSURL *)syncURL authServerURL:(NSURL *)authServerURL;

@end
