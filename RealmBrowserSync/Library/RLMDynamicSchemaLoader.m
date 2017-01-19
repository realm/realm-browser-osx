////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

@import Realm.Private;

#import "RLMDynamicSchemaLoader.h"

static NSTimeInterval const schemaLoadTimeout = 5;

NSString * const errorDomain = @"RLMDynamicSchemaLoader";

@interface RLMDynamicSchemaLoader()

@property (nonatomic, strong) RLMRealmConfiguration *configuration;
@property (nonatomic, strong) RLMNotificationToken *notificationToken;
@property (nonatomic, strong) RLMSchemaLoadCompletionHandler completionHandler;

@end

@implementation RLMDynamicSchemaLoader

- (instancetype)initWithSyncURL:(NSURL *)syncURL user:(RLMSyncUser *)user {
    NSAssert(user.state == RLMSyncUserStateActive, @"User must be logged in");

    self = [super init];

    if (self != nil) {
        self.configuration = [[RLMRealmConfiguration alloc] init];
        self.configuration.dynamic = YES;
        self.configuration.syncConfiguration = [[RLMSyncConfiguration alloc] initWithUser:user realmURL:syncURL];
    }

    return self;
}

- (void)dealloc {
    [self cancelSchemaLoading];
}

- (void)loadSchemaWithCompletionHandler:(RLMSchemaLoadCompletionHandler)handler {
    self.completionHandler = handler;

    NSError *error;

    RLMRealm *realm = [RLMRealm realmWithConfiguration:self.configuration error:&error];

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

        // FIXME: Looks like there is an issue with closing realm and opening it the second time
        // so will keep realm opened until dealloc for now
        // [weakSelf.notificationToken stop];
        [weakSelf schemaDidLoadWithError:nil];
    }];

    [self performSelector:@selector(schemaLoadingTimeout) withObject:nil afterDelay:schemaLoadTimeout];
}

- (void)cancelSchemaLoading {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self.notificationToken stop];
}

- (void)schemaDidLoadWithError:(NSError *)error {
    if (self.completionHandler != nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.completionHandler(error);
            self.completionHandler = nil;
        });
    }
}

- (void)schemaLoadingTimeout {
    [self.notificationToken stop];
    [self schemaDidLoadWithError:[self errorWithCode:0 description:@"Failed to connect to Object Server." recoverySuggestion:@"Check the URL and that the server is accessible."]];
}

- (NSError *)errorWithCode:(NSInteger)code description:(NSString *)description recoverySuggestion:(NSString *)recoverySuggestion {
    NSDictionary *userInfo = @{
        NSLocalizedDescriptionKey: description,
        NSLocalizedRecoverySuggestionErrorKey: recoverySuggestion
    };

    return [NSError errorWithDomain:errorDomain code:code userInfo:userInfo];
}

@end
