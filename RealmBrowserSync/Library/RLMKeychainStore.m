//
//  RLMKeychainStore.m
//  RealmBrowser
//
//  Created by Guilherme Rambo on 11/04/17.
//  Copyright © 2017 Realm inc. All rights reserved.
//

#import "RLMKeychainStore.h"

#import "RLMKeychainInfo.h"

@import Security;
@import Realm;

const char * kRLMKeychainServiceName = "Realm Browser";

NSString * const kRLMKeychainTokenKey = @"token";
NSString * const kRLMKeychainPasswordKey = @"password";
NSString * const kRLMKeychainProviderKey = @"provider";

@interface RLMKeychainInfo (KeychainDictionary)

+ (instancetype)keychainInfoFromKeychainDictionary:(NSDictionary *)dict;

@end

@implementation RLMKeychainStore

- (void)saveCredentials:(RLMSyncCredentials *)credentials forServer:(NSURL *)serverURL
{
    if (!credentials.userInfo || !credentials.token) return;
    
    UInt32 serverAddressLength = (UInt32)serverURL.absoluteString.length;
    const char *serverAddress = serverURL.absoluteString.UTF8String;
    
    NSDictionary *accountInfo = [self keychainDictionaryFromCredentials:credentials];
    
    NSData *plist = [NSPropertyListSerialization dataWithPropertyList:accountInfo format:NSPropertyListXMLFormat_v1_0 options:NSPropertyListImmutable error:NULL];
    
    if (!plist) return;
    
    SecKeychainAddGenericPassword(NULL,
                                  (UInt32)strlen(kRLMKeychainServiceName),
                                  kRLMKeychainServiceName,
                                  serverAddressLength,
                                  serverAddress,
                                  (UInt32)plist.length,
                                  plist.bytes,
                                  NULL);
}

- (RLMKeychainInfo *)savedCredentialsForServer:(NSURL *)serverURL
{
    UInt32 serverAddressLength = (UInt32)serverURL.absoluteString.length;
    const char *serverAddress = serverURL.absoluteString.UTF8String;
    
    void *plistPointer;
    UInt32 plistLength = 0;
    
    OSStatus result = SecKeychainFindGenericPassword(NULL, (UInt32)strlen(kRLMKeychainServiceName), kRLMKeychainServiceName, serverAddressLength, serverAddress, &plistLength, &plistPointer, NULL);
    if (result != noErr || plistLength <= 0) return nil;
    
    NSData *plistData = [NSData dataWithBytes:plistPointer length:(NSUInteger)plistLength];
    
    NSDictionary *dict = [NSPropertyListSerialization propertyListWithData:plistData options:NSPropertyListImmutable format:NULL error:nil];
    if (!dict) return nil;
    
    return [RLMKeychainInfo keychainInfoFromKeychainDictionary:dict];
}

#pragma mark Private

- (NSDictionary *)keychainDictionaryFromCredentials:(RLMSyncCredentials *)credentials
{
    NSMutableDictionary *dict = [NSMutableDictionary new];
    
    dict[kRLMKeychainTokenKey] = credentials.token;
    
    if (credentials.userInfo) {
        NSString *password = credentials.userInfo[kRLMKeychainPasswordKey];
        if (password) dict[kRLMKeychainPasswordKey] = password;
    }
    
    dict[kRLMKeychainProviderKey] = credentials.provider;
    
    return [dict copy];
}

@end

@implementation RLMKeychainInfo (KeychainDictionary)

+ (instancetype)keychainInfoFromKeychainDictionary:(NSDictionary *)dict
{
    RLMKeychainInfo *info = [RLMKeychainInfo new];
    
    info.token = dict[kRLMKeychainTokenKey];
    info.password = dict[kRLMKeychainPasswordKey];
    info.provider = dict[kRLMKeychainProviderKey];
    
    return info;
}

@end
