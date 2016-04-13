//
//  RLMRunSyncServerWindowController.m
//  RealmBrowser
//
//  Created by Tim Oliver on 23/03/2016.
//  Copyright © 2016 Realm inc. All rights reserved.
//

#import "RLMRunSyncServerWindowController.h"

@interface RLMRunSyncServerWindowController ()

@property (nonatomic, strong) NSTask *serverTask;
@property (nonatomic, strong) NSPipe *serverPipe;

- (IBAction)runServerButtonClicked:(id)sender;
- (IBAction)stopServerButtonClicked:(id)sender;

- (void)startServer;
- (void)stopServer;

- (void)receivedData:(NSNotification *)notification;

@end

@implementation RLMRunSyncServerWindowController

- (instancetype)init {
    if (self = [super initWithWindowNibName:@"SyncServerWindow"]) {
        
    }
    
    return self;
}

- (void)startServer
{
    if (self.serverTask) {
        return;
    }
    
    NSString *serverBinaryPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"realm-server-noinst"];
    
    self.serverTask = [[NSTask alloc] init];
    self.serverTask.launchPath = serverBinaryPath;
    
    NSMutableArray *arguments = [NSMutableArray array];
    
    self.serverPipe = [[NSPipe alloc] init];
    self.serverTask.standardOutput = self.serverPipe;
    
    NSFileHandle *fileHandle = self.serverPipe.fileHandleForReading;
    [fileHandle waitForDataInBackgroundAndNotify];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedData:) name:NSFileHandleDataAvailableNotification object:fileHandle];
    
    [self.serverTask launch];
}

- (void)stopServer
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleDataAvailableNotification object:self.serverPipe.fileHandleForReading];
    
}

- (void)receivedData:(NSNotification *)notification
{
    NSFileHandle *fileHandle = notification.object;
    NSData *data = fileHandle.availableData;
    
    if (data.length > 0) {
        [fileHandle waitForDataInBackgroundAndNotify];
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        self.consoleOutputField.stringValue = [self.consoleOutputField.stringValue stringByAppendingString:str];
    }
}

- (IBAction)runServerButtonClicked:(id)sender
{
    [self startServer];
}

- (IBAction)stopServerButtonClicked:(id)sender
{
    [self stopServer];
}

@end
