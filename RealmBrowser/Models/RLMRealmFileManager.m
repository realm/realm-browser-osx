 //
//  RLMRealmFileManager.m
//  RealmBrowser
//
//  Created by Tim Oliver on 22/04/2016.
//  Copyright © 2016 Realm inc. All rights reserved.
//

@import Realm;

#import "RLMRealmFileManager.h"

@interface RLMRealmFileManager ()

@property (nonatomic, strong) NSMutableDictionary *realms;

@end

@implementation RLMRealmFileManager

+ (instancetype)sharedManager
{
    static dispatch_once_t onceToken;
    static RLMRealmFileManager *_sharedManager;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[RLMRealmFileManager alloc] init];
    });
    
    return _sharedManager;
}

- (instancetype)init
{
    if (self = [super init]) {
        _realms = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void)addRealm:(RLMRealm *)realm
{
    if (realm == nil) {
        return;
    }
    
    self.realms[realm.configuration.fileURL] = realm;
}

- (RLMRealm *)realmForPath:(NSString *)path
{
    if (path.length == 0) {
        return nil;
    }
    
    return self.realms[path];
}

- (void)removeRealm:(RLMRealm *)realm
{
    if (realm == nil) {
        return;
    }
    
    [self.realms removeObjectForKey:realm.configuration.fileURL];
}

@end
