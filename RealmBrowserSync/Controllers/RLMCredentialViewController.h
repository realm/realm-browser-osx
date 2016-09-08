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

@property (nonatomic, strong) RLMSyncCredential *credential;
@property (nonatomic, strong) NSURL *authServerURL;

@end
