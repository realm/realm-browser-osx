//
//  RLMKeychainInfo.h
//  RealmBrowser
//
//  Created by Guilherme Rambo on 11/04/17.
//  Copyright © 2017 Realm inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RLMKeychainInfo : NSObject

@property (nonatomic, copy) NSString *provider;
@property (nonatomic, copy) NSString *token;
@property (nonatomic, copy) NSString *password;

@end
