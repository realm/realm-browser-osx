//
//  RLMKeychainInfo+RLMSyncCredentials.h
//  RealmBrowser
//
//  Created by Guilherme Rambo on 12/04/17.
//  Copyright © 2017 Realm inc. All rights reserved.
//

#import "RLMKeychainInfo.h"

@import Realm;

@interface RLMKeychainInfo (RLMSyncCredentials)

@property (nonatomic, readonly) RLMSyncCredentials *credentials;

@end
