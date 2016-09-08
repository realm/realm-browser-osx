//
//  RLMDynamicSchemaLoader.h
//  RealmBrowser
//
//  Created by Dmitry Obukhov on 17/08/16.
//  Copyright © 2016 Realm inc. All rights reserved.
//

@import Realm;

typedef void (^RLMSchemaLoadCompletionHandler)(NSError *error);

@interface RLMDynamicSchemaLoader : NSObject

- (instancetype)initWithSyncURL:(NSURL *)syncURL user:(RLMSyncUser *)user;

- (void)loadSchemaWithCompletionHandler:(RLMSchemaLoadCompletionHandler)handler;

@end
