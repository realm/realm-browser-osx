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

+ (RLMSyncCredentials *)emptyCredentialsWithProvider:(RLMIdentityProvider)provider
{
    if ([provider isEqualToString:RLMIdentityProviderUsernamePassword]) {
        return [RLMSyncCredentials credentialsWithUsername:@"" password:@"" register:NO];
    } else if ([provider isEqualToString:RLMIdentityProviderGoogle]) {
        return [RLMSyncCredentials credentialsWithGoogleToken:@""];
    } else if ([provider isEqualToString:RLMIdentityProviderCloudKit]) {
        return [RLMSyncCredentials credentialsWithCloudKitToken:@""];
    } else if ([provider isEqualToString:RLMIdentityProviderFacebook]) {
        return [RLMSyncCredentials credentialsWithFacebookToken:@""];
    } else {
        return [RLMSyncCredentials credentialsWithAccessToken:@"" identity:[NSUUID UUID].UUIDString];
    }
}

- (BOOL)isEqualToCredentials:(RLMSyncCredentials *)credentials
{
    return [credentials.provider isEqualToString:self.provider]
            && [credentials.token isEqualToString:self.token]
            && [credentials.userInfo[@"password"] isEqualToString:self.password];
}

@end
