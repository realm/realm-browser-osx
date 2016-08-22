//
//  RLMRealmConfiguration+Sync.h
//  RealmBrowser
//
//  Created by Dmitry Obukhov on 17/08/16.
//  Copyright © 2016 Realm inc. All rights reserved.
//

#import <Realm/Realm.h>

@interface RLMRealmConfiguration (Sync)

+ (instancetype)dynamicSchemaConfigurationWithSyncServerURL:(NSURL *)syncServerURL serverPath:(NSString *)serverPath accessToken:(NSString *)accessToken fileURL:(NSURL *)fileURL;

+ (instancetype)dynamicSchemaConfigurationWithSyncURL:(NSURL *)syncURL accessToken:(NSString *)accessToken fileURL:(NSURL *)fileURL;

@end
