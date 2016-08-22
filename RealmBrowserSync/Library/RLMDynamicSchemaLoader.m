//
//  RLMDynamicSchemaLoader.m
//  RealmBrowser
//
//  Created by Dmitry Obukhov on 17/08/16.
//  Copyright © 2016 Realm inc. All rights reserved.
//

@import Realm;

#import "RLMDynamicSchemaLoader.h"
#import "RLMRealmConfiguration+Sync.h"

static NSTimeInterval const schemaLoadTimeout = 5;

NSString * const errorDomain = @"RLMDynamicSchemaLoader";

@interface RLMDynamicSchemaLoader()

@property (nonatomic, strong) RLMNotificationToken *notificationToken;
@property (nonatomic, strong) RLMSchemaLoadCompletionHandler completionHandler;

@end

@implementation RLMDynamicSchemaLoader

- (void)loadSchemaFromSyncURL:(NSURL *)syncURL accessToken:(NSString *)accessToken toRealmFileURL:(NSURL *)fileURL completionHandler:(RLMSchemaLoadCompletionHandler)handler {
    self.completionHandler = handler;

    NSError *error;

    RLMRealmConfiguration *configuration = [RLMRealmConfiguration dynamicSchemaConfigurationWithSyncURL:syncURL accessToken:accessToken fileURL:fileURL];
    RLMRealm *realm = [RLMRealm realmWithConfiguration:configuration error:&error];

    if (error != nil) {
        [self schemaDidLoadWithError:error];
        return;
    }

    if (realm.schema.objectSchema.count > 0) {
        [self schemaDidLoadWithError:nil];
        return;
    }

    __weak typeof(self) weakSelf = self;
    self.notificationToken = [realm addNotificationBlock:^(RLMNotification notification, RLMRealm *realm) {
        [NSObject cancelPreviousPerformRequestsWithTarget:weakSelf];

        [weakSelf.notificationToken stop];
        [weakSelf schemaDidLoadWithError:nil];
    }];

    [self performSelector:@selector(schemaDidLoadWithError:) withObject:[self errorWithCode:0 description:@"Failed to connect to Sync Server." recoverySuggestion:@"Check the URL and that the server is accessible."] afterDelay:schemaLoadTimeout];
}

- (void)schemaDidLoadWithError:(NSError *)error {
    if (self.completionHandler != nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.completionHandler(error);
            self.completionHandler = nil;
        });
    }
}

- (NSError *)errorWithCode:(NSInteger)code description:(NSString *)description recoverySuggestion:(NSString *)recoverySuggestion {
    NSDictionary *userInfo = @{
        NSLocalizedDescriptionKey: description,
        NSLocalizedRecoverySuggestionErrorKey: recoverySuggestion
    };

    return [NSError errorWithDomain:errorDomain code:code userInfo:userInfo];
}

@end
