//
//  RLMKeychainStore.h
//  RealmBrowser
//
//  Created by Guilherme Rambo on 11/04/17.
//  Copyright © 2017 Realm inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RLMSyncCredentials, RLMKeychainInfo;

@interface RLMKeychainStore : NSObject

- (void)saveCredentials:(RLMSyncCredentials *)credentials forServer:(NSURL *)serverURL;
- (RLMKeychainInfo *)savedCredentialsForServer:(NSURL *)serverURL;

@end
