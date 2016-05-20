//
//  RLMSyncServer.m
//  RealmBrowser
//
//  Created by Tim Oliver on 23/03/2016.
//  Copyright © 2016 Realm inc. All rights reserved.
//

#import "RLMSyncServer.h"

@interface RLMSyncServer ()

@property (nonatomic, strong) NSTask *task;
@property (nonatomic, strong) NSPipe *pipe;
@property (nonatomic, strong) NSFileHandle *fileHandle;

@property (nonatomic, assign, readwrite) BOOL serverIsRunning;
@property (nonatomic, copy, readwrite) NSString *consoleOutput;

- (void)dataReceived:(NSNotification *)notification;

@end

@implementation RLMSyncServer

+ (instancetype)sharedServer
{
    static RLMSyncServer *_sharedServer;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedServer = [[RLMSyncServer alloc] init];
    });
    
    return _sharedServer;
}

- (instancetype)init
{
    if (self = [super init]) {
        _loggingLevel = 1;
        _consoleOutput = @"";
        _realmDirectoryFilePath = @"~/Realm-Sync-Server";
    }
    
    return self;
}

- (void)startServer
{
    if (self.serverIsRunning) {
        return;
    }
    
    self.task = [[NSTask alloc] init];
    self.task.launchPath = @"";
    self.task.arguments = @[];
    
    self.pipe = [[NSPipe alloc] init];
    self.task.standardOutput = self.pipe;
    
    self.fileHandle = self.pipe.fileHandleForReading;
    [self.fileHandle waitForDataInBackgroundAndNotify];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataReceived:) name:NSFileHandleDataAvailableNotification object:self.fileHandle];
}

- (void)stopServer
{
    if (!self.serverIsRunning) {
        return;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleDataAvailableNotification object:self.fileHandle];
    self.fileHandle = nil;
    
    self.pipe = nil;
    self.task = nil;
}

- (void)dataReceived:(NSNotification *)notification
{
    NSFileHandle *handle = notification.object;
    NSData *newData = handle.availableData;
    if (newData.length > 0) {
        NSString *string = [[NSString alloc] initWithData:newData encoding:NSUTF8StringEncoding];
        self.consoleOutput = [self.consoleOutput stringByAppendingString:string];
    }
    
    [handle waitForDataInBackgroundAndNotify];
}

@end
