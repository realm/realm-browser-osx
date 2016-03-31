//
//  RLMSyncServer.h
//  RealmBrowser
//
//  Created by Tim Oliver on 23/03/2016.
//  Copyright © 2016 Realm inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RLMSyncServer : NSObject

@property (nonatomic, copy) NSString *host;
@property (nonatomic, copy) NSString *port;

@property (nonatomic, copy) NSString *realmDirectoryFilePath;
@property (nonatomic, copy) NSString *publicKeyFilePath;
@property (nonatomic, assign) BOOL noReuseAddress;
@property (nonatomic, assign) NSInteger loggingLevel;

@property (nonatomic, readonly) BOOL serverIsRunning;

@property (nonatomic, readonly) NSString *consoleOutput;

@property (nonatomic, copy) void (^outputUpdatedHandler)();

+ (instancetype)sharedServer;

- (void)startServer;
- (void)stopServer;

@end
