//
//  SyncServer.h
//  RealmSyncServer
//
//  Created by Dmitry Obukhov on 21/06/16.
//  Copyright © 2016 Realm Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, SyncServerLogLevel) {
    SyncServerLogLevelNormal = 0,
    SyncServerLogLevelEverything
};

extern NSString * const SyncServerErrorDomain;

typedef NS_ENUM(NSInteger, SyncServerError) {
    SyncServerErrorLoadingPublicKey = 0,
    SyncServerErrorOpenningRootDirectory,
    SyncServerErrorStartingServer
};

@class SyncServer;

@protocol SyncServerDelegate

- (void)syncServer:(SyncServer *)server didOutputLogMessage:(NSString *)message;
- (void)syncServerDidStop:(SyncServer *)server;

@end

@interface SyncServer : NSObject

@property (nonatomic, copy) NSURL *rootDirectoryURL;
@property (nonatomic, copy, nullable) NSURL *publicKeyURL;
@property (nonatomic, copy) NSString *host;
@property (nonatomic) NSInteger port;
@property (nonatomic) SyncServerLogLevel logLevel;

@property (nonatomic, readonly, getter=isRunning) BOOL running;

@property (nonatomic, weak, nullable) id<SyncServerDelegate> delegate;

- (BOOL)start:(NSError *__autoreleasing *)error;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
