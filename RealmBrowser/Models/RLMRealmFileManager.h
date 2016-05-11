//
//  RLMRealmFileManager.h
//  RealmBrowser
//
//  Created by Tim Oliver on 22/04/2016.
//  Copyright © 2016 Realm inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RLMRealm;

@interface RLMRealmFileManager : NSObject

+ (instancetype)sharedManager;

- (void)addRealm:(RLMRealm *)realm;
- (RLMRealm *)realmForPath:(NSString *)path;
- (void)removeRealm:(RLMRealm *)realm;

@end
