//
//  SyncServer.h
//  RealmSyncServer
//
//  Created by Dmitry Obukhov on 21/06/16.
//  Copyright © 2016 Realm Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, SyncServerLogLevel) {
    SyncServerLogLevelDefault,
    SyncServerLogLevelNone
};

extern NSString * _Nonnull const SyncServerErrorDomain;

@class SyncServer;

@protocol SyncServerDelegate

- (void)syncServer:(SyncServer * _Nonnull)server didOutputLogMessage:(NSString * _Nonnull)message;
- (void)syncServerDidStop:(SyncServer * _Nonnull)server;

@end

@interface SyncServer : NSObject

@property (nonatomic, copy) NSURL * _Nonnull rootDirectoryURL;
@property (nonatomic, copy) NSURL * _Nullable publicKeyURL;
@property (nonatomic, copy) NSString * _Nonnull host;
@property (nonatomic, assign) NSInteger port;
@property (nonatomic, assign) SyncServerLogLevel logLevel;

@property (nonatomic, assign, readonly, getter=isRunning) BOOL running;

@property (nonatomic, weak) id<SyncServerDelegate> _Nullable delegate;

- (BOOL)start:(NSError *__autoreleasing _Nullable * _Nonnull)error;
- (void)stop;

@end
