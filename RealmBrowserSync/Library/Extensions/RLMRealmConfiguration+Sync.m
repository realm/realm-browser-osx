//
//  RLMRealmConfiguration+Sync.m
//  RealmBrowser
//
//  Created by Dmitry Obukhov on 17/08/16.
//  Copyright © 2016 Realm inc. All rights reserved.
//

@import Realm.Private;

#import "RLMRealmConfiguration+Sync.h"

@implementation RLMRealmConfiguration (Sync)

+ (instancetype)dynamicSchemaConfigurationWithSyncServerURL:(NSURL *)serverURL serverPath:(NSString *)serverPath accessToken:(NSString *)accessToken fileURL:(NSURL *)fileURL {
    RLMCredential *credentials = [RLMCredential credentialWithAccessToken:accessToken serverURL:serverURL];

    RLMUser *user = [[RLMUser alloc] initWithLocalIdentity:nil];
    [user loginWithCredential:credentials completion:nil];

    RLMRealmConfiguration *configuration = [[RLMRealmConfiguration alloc] init];
    configuration.dynamic = YES;
    configuration.customSchema = nil;
    
    [configuration setObjectServerPath:serverPath forUser:user];

    if (fileURL != nil) {
        configuration.fileURL = fileURL;
    }

    return configuration;
}

+ (instancetype)dynamicSchemaConfigurationWithSyncURL:(NSURL *)syncURL accessToken:(NSString *)accessToken fileURL:(NSURL *)fileURL {
    NSURL *serverURL = [NSURL URLWithString:@"/" relativeToURL:syncURL].absoluteURL;
    NSString *serverPath = syncURL.path;

    return [self dynamicSchemaConfigurationWithSyncServerURL:serverURL serverPath:serverPath accessToken:accessToken fileURL:fileURL];
}

@end
