//
//  RLMCredentialViewController.h
//  RealmBrowser
//
//  Created by Dmitry Obukhov on 31/08/16.
//  Copyright © 2016 Realm inc. All rights reserved.
//

@import Cocoa;
@import Realm;

@interface RLMCredentialViewController : NSViewController

@property (nonatomic, strong) RLMCredential *credential;
@property (nonatomic, strong) NSURL *serverURL;

- (instancetype)initWithServerURL:(NSURL *)serverURL credential:(RLMCredential *)credential;

@end
