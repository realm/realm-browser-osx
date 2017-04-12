//
//  RLMKeychainInfo+RLMSyncCredentials.m
//  RealmBrowser
//
//  Created by Guilherme Rambo on 12/04/17.
//  Copyright © 2017 Realm inc. All rights reserved.
//

#import "RLMKeychainInfo+RLMSyncCredentials.h"

@implementation RLMKeychainInfo (RLMSyncCredentials)

- (RLMSyncCredentials *)credentials
{
    if ([self.provider isEqualToString:RLMIdentityProviderUsernamePassword]) {
        return [RLMSyncCredentials credentialsWithUsername:self.token password:self.password register:NO];
    } else if ([self.provider isEqualToString:RLMIdentityProviderGoogle]) {
        return [RLMSyncCredentials credentialsWithGoogleToken:self.token];
    } else if ([self.provider isEqualToString:RLMIdentityProviderCloudKit]) {
        return [RLMSyncCredentials credentialsWithCloudKitToken:self.token];
    } else if ([self.provider isEqualToString:RLMIdentityProviderFacebook]) {
        return [RLMSyncCredentials credentialsWithFacebookToken:self.token];
    } else {
        return [RLMSyncCredentials credentialsWithAccessToken:self.token identity:[NSUUID UUID].UUIDString];
    }
}

@end
