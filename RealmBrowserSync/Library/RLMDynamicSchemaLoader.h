//
//  RLMDynamicSchemaLoader.h
//  RealmBrowser
//
//  Created by Dmitry Obukhov on 17/08/16.
//  Copyright © 2016 Realm inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^RLMSchemaLoadCompletionHandler)(NSError *error);

@interface RLMDynamicSchemaLoader : NSObject

- (instancetype)initWithSyncURL:(NSURL *)syncURL user:(RLMUser *)user;

- (void)loadSchemaToURL:(NSURL *)fileURL completionHandler:(RLMSchemaLoadCompletionHandler)handler;

- (void)loadSchemaFromSyncURL:(NSURL *)syncURL accessToken:(NSString *)accessToken toRealmFileURL:(NSURL *)fileURL completionHandler:(RLMSchemaLoadCompletionHandler)handler;

@end
