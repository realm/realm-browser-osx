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
@property (nonatomic, strong) NSPipe *serverErrorPipe;
@property (nonatomic, strong) NSPipe *serverOutputPipe;

@property (nonatomic, readonly) NSString *IPAddressString;
@property (nonatomic, readonly) NSString *realmFolderPath;
@property (nonatomic, readonly) NSString *publicKeyPath;

- (IBAction)runServerButtonClicked:(id)sender;
- (IBAction)stopServerButtonClicked:(id)sender;

- (void)startServer;
- (void)stopServer;

- (void)receivedData:(NSNotification *)notification;

- (IBAction)selectRealmFolderButtonClicked:(id)sender;
- (IBAction)selectPublicKeyFileButtonClicked:(id)sender;

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
    
    NSString *resourcePath =[[NSBundle mainBundle] resourcePath];
    NSString *serverBinaryPath = [resourcePath stringByAppendingPathComponent:@"realm-server-dbg-noinst"];
    
    self.serverTask = [[NSTask alloc] init];
    self.serverTask.launchPath = serverBinaryPath;
    self.serverTask.environment = @{@"DYLD_LIBRARY_PATH":resourcePath};
    
    NSMutableArray *arguments = [NSMutableArray array];
//    /[arguments addObject:@"--help"];
    
    [arguments addObject:self.realmFolderPath];
    [arguments addObject:self.IPAddressString];
    
    if (self.publicKeyPath.length > 0) {
        [arguments addObject:@"-k"];
        [arguments addObject:self.publicKeyPath];
    }
        
    if (self.portTextField.stringValue.length > 0) {
        [arguments addObject:@"-p"];
        [arguments addObject:self.portTextField.stringValue];
    }
    
    if (self.noReuseCheckbox.state > 0) {
        [arguments addObject:@"-r"];
    }
    
    if (self.loggingLevelPopup.indexOfSelectedItem > 0) {
        [arguments addObject:@"-l"];
        [arguments addObject:[NSString stringWithFormat:@"%ld", (long)self.loggingLevelPopup.indexOfSelectedItem]];
    }
    
    self.serverTask.arguments = arguments;
    
    self.serverOutputPipe = [NSPipe pipe];
    self.serverErrorPipe = [NSPipe pipe];
    
    self.serverTask.standardOutput  = self.serverOutputPipe;
    [self.serverOutputPipe.fileHandleForReading waitForDataInBackgroundAndNotify];
    
    self.serverTask.standardError = self.serverErrorPipe;
    [self.serverErrorPipe.fileHandleForReading waitForDataInBackgroundAndNotify];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedData:) name:NSFileHandleDataAvailableNotification object:self.serverErrorPipe.fileHandleForReading];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedData:) name:NSFileHandleDataAvailableNotification object:self.serverOutputPipe.fileHandleForReading];
    
    [self.serverTask launch];
    
    self.startServerButton.enabled = NO;
    self.stopServerButton.enabled = YES;
}

- (void)stopServer
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleDataAvailableNotification object:self.serverErrorPipe.fileHandleForReading];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleDataAvailableNotification object:self.serverOutputPipe.fileHandleForReading];
    
    self.serverTask = nil;
    self.serverOutputPipe = nil;
    self.serverErrorPipe = nil;
    
    self.startServerButton.enabled = YES;
    self.stopServerButton.enabled = NO;
}

- (void)receivedData:(NSNotification *)notif {
    NSFileHandle *fh = [notif object];
    NSData *data = [fh availableData];
    if (data.length > 0) { // if data is found, re-register for more data (and print)
        [fh waitForDataInBackgroundAndNotify];
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

- (IBAction)selectRealmFolderButtonClicked:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.canChooseFiles = NO;
    openPanel.canChooseDirectories = YES;
    openPanel.canCreateDirectories = YES;
    [openPanel runModal];
    
    NSURL *folderURL = openPanel.URL;
    if (folderURL == nil) {
        return;
    }
    
    self.realmDirectoryTextField.stringValue = folderURL.path;
}

- (IBAction)selectPublicKeyFileButtonClicked:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.canChooseFiles = YES;
    openPanel.canChooseDirectories = NO;
    openPanel.allowedFileTypes = @[@"pem"];
    [openPanel runModal];
    
    NSURL *fileURL = openPanel.URL;
    if (fileURL == nil) {
        return;
    }
    
    self.publicTextField.stringValue = fileURL.path;
}

#pragma mark - Argument Creation/Sanitation Accessors -
- (NSString *)IPAddressString
{
    NSString *IPAddressString = self.hostTextField.stringValue;
    if (IPAddressString.length == 0) {
        IPAddressString = self.hostTextField.placeholderString;
    }
    
    return IPAddressString;
}

- (NSString *)realmFolderPath
{
    //The folder to host the sync-created Realm files
    NSString *realmFolderPath = self.realmDirectoryTextField.stringValue;
    if (realmFolderPath.length == 0) {
        realmFolderPath = self.realmDirectoryTextField.placeholderString;
    }
    
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:realmFolderPath] == NO) {
        [manager createDirectoryAtPath:realmFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return realmFolderPath;
}

- (NSString *)publicKeyPath
{
    NSString *publicKeyPath = self.publicTextField.stringValue;
    if (publicKeyPath.length == 0) {
        return nil;
    }
    
    return publicKeyPath;
}

@end
