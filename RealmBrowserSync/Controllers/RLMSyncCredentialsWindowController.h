//
//  RLMSyncCredentialsWindowController.h
//  RealmBrowser
//
//  Created by Dmitry Obukhov on 16/08/16.
//  Copyright © 2016 Realm inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString * const RLMSyncCredentialsWindowControllerErrorDomain;

@interface RLMSyncCredentialsWindowController : NSWindowController

@property (nonatomic, copy) NSURL *url;
@property (nonatomic, copy) NSString *token;

- (BOOL)validateCredentials:(NSError *__autoreleasing *)error;

- (NSModalResponse)runModal;

@end
