//
//  RLMSyncAuthWindowController.m
//  RealmBrowser
//
//  Created by Tim Oliver on 30/03/2016.
//  Copyright © 2016 Realm inc. All rights reserved.
//

#import "RLMSyncAuthWindowController.h"

@interface RLMSyncAuthWindowController () <NSWindowDelegate>

- (void)performAuthentication;
- (void)generateKeyFilesAtURL:(NSURL *)URL;
- (void)generateManifestFileAtURL:(NSURL *)URL;
- (void)signManifestFileAtURL:(NSURL *)URL;

@end

@implementation RLMSyncAuthWindowController

- (instancetype)init {
    if (self = [super initWithWindowNibName:@"RLMSyncAuthWindowController"]) {
    
    }
    
    return self;
}

- (IBAction)proceedButtonClicked:(id)sender
{
    [self performAuthentication];
}

- (IBAction)cancelButtonClicked:(id)sender
{
    [self close];
}

- (void)windowWillClose:(NSNotification *)notification
{
    if (self.closedHandler) {
        self.closedHandler();
    }
}

- (void)performAuthentication
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.allowsMultipleSelection = NO;
    openPanel.canChooseFiles = NO;
    openPanel.canChooseDirectories = YES;
    openPanel.canCreateDirectories = YES;
    openPanel.message = @"Please select a destination directory for the authentication files.";
    [openPanel beginWithCompletionHandler:^(NSInteger result) {
        if (result != NSFileHandlingPanelOKButton) {
            return;
        }
       
        dispatch_async(dispatch_get_main_queue(), ^{
            [self generateKeyFilesAtURL:openPanel.URL];
        });
    }];
}

- (void)generateKeyFilesAtURL:(NSURL *)URL
{
    NSURL *folderURL = URL;
    if (folderURL == nil) {
        return;
    }
    
    NSString *passphrase = nil;
    if (self.passPhraseTextField.stringValue.length > 0) {
        passphrase = self.passPhraseTextField.stringValue;
    }
    else {
        passphrase = self.passPhraseTextField.placeholderString;
    }
    
    NSTask *privateKeyTask = [[NSTask alloc] init];
    NSString *passphraseInput = [NSString stringWithFormat:@"pass:\"%@\"", passphrase];
    NSString *privateFilePath = [folderURL.path stringByAppendingPathComponent:@"private.pem"];
    NSString *publicFilePath = [folderURL.path stringByAppendingPathComponent:@"public.pem"];
    
    // Step 1 - Generate the private RSA key
    privateKeyTask.launchPath = @"/usr/bin/openssl";
    privateKeyTask.arguments = @[@"genrsa", @"-aes256", @"-passout", passphraseInput, @"-out", privateFilePath, @"2048"];
    [privateKeyTask launch];
    [privateKeyTask waitUntilExit];
    
    //Step 2 - Export the public RSA key
    NSTask *publicKeyTask = [[NSTask alloc] init];
    publicKeyTask.launchPath = @"/usr/bin/openssl";
    publicKeyTask.arguments = @[@"rsa", @"-in", privateFilePath, @"-outform", @"PEM", @"-passin", passphraseInput, @"-pubout", @"-out", publicFilePath];
    [publicKeyTask launch];
    [publicKeyTask waitUntilExit];
    
    //Step 3 - Generate a manifest file
    [self generateManifestFileAtURL:URL];
}

- (void)generateManifestFileAtURL:(NSURL *)URL
{
    NSMutableArray *accesses = [NSMutableArray array];
    if (self.uploadAccessButton.state > 0) {
        [accesses addObject:@"upload"];
    }
    if (self.downloadAccessButton.state > 0) {
        [accesses addObject:@"download"];
    }
    
    NSMutableDictionary *jsonDict = [NSMutableDictionary dictionary];
    jsonDict[@"auth_method"] = @"none";
    jsonDict[@"access"] = accesses;
    jsonDict[@"app_id"] = self.appBundleTextField.stringValue ? self.appBundleTextField.stringValue : self.appBundleTextField.placeholderString;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonPath = [URL.path stringByAppendingPathComponent:@"manifest.json"];
    [jsonData writeToFile:jsonPath atomically:YES];
    
    [self signManifestFileAtURL:[NSURL fileURLWithPath:jsonPath]];
}

- (void)signManifestFileAtURL:(NSURL *)URL
{
    NSTask *catManifestTask = [[NSTask alloc] init];
    NSPipe *catManifestPipe = [[NSPipe alloc] init];
    catManifestTask.launchPath = @"/bin/cat";
    catManifestTask.arguments = @[URL.path];
    catManifestTask.standardOutput = catManifestPipe;
    [catManifestTask waitUntilExit];
    [catManifestTask launch];
    
    NSTask *manifestBase64Task = [[NSTask alloc] init];
    NSPipe *manifestBase64Pipe = [[NSPipe alloc] init];
    manifestBase64Task.launchPath = @"/usr/bin/base64";
    manifestBase64Task.standardInput = catManifestPipe;
    manifestBase64Task.standardOutput = manifestBase64Pipe;
    [manifestBase64Task waitUntilExit];
    [manifestBase64Task launch];
    
    NSData *data = [[manifestBase64Pipe fileHandleForReading] readDataToEndOfFile];
    NSString *base64String = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    //cat my_token.json | openssl dgst -sha256 -binary -sign private.pem | base64
    
    NSString *passphrase = nil;
    if (self.passPhraseTextField.stringValue.length > 0) {
        passphrase = self.passPhraseTextField.stringValue;
    }
    else {
        passphrase = self.passPhraseTextField.placeholderString;
    }
    NSString *passphraseInput = [NSString stringWithFormat:@"pass:\"%@\"", passphrase];
    NSString *privateKeypath = [[URL.path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"private.pem"];
    
    NSTask *catManifestSignTask = [[NSTask alloc] init];
    NSPipe *catManifestSignPipe = [[NSPipe alloc] init];
    catManifestSignTask.launchPath = @"/bin/cat";
    catManifestSignTask.arguments = @[URL.path];
    catManifestSignTask.standardOutput = catManifestSignPipe;
    [catManifestSignTask waitUntilExit];
    [catManifestSignTask launch];
    
    NSTask *manifestSignTask = [[NSTask alloc] init];
    NSPipe *manifestSignPipe = [[NSPipe alloc] init];
    manifestSignTask.launchPath = @"/usr/bin/openssl";
    manifestSignTask.arguments = @[@"dgst", @"-sha256", @"-binary", @"-passin", passphraseInput, @"-sign", privateKeypath];
    manifestSignTask.standardInput = catManifestSignPipe;
    manifestSignTask.standardOutput = manifestSignPipe;
    [manifestSignTask waitUntilExit];
    [manifestSignTask launch];
    
    NSTask *manifestBase64SignTask = [[NSTask alloc] init];
    NSPipe *manifestBase64SignPipe = [[NSPipe alloc] init];
    manifestBase64SignTask.launchPath = @"/usr/bin/base64";
    manifestBase64SignTask.standardInput = manifestSignPipe;
    manifestBase64SignTask.standardOutput = manifestBase64SignPipe;
    [manifestBase64SignTask waitUntilExit];
    [manifestBase64SignTask launch];
    
    data = [[manifestBase64SignPipe fileHandleForReading] readDataToEndOfFile];
    NSString *base64SignedString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSString *filePath = [[URL.path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Credentials.txt"];
    NSString *output = [NSString stringWithFormat:@"syncIdentity:\n%@\n\nsyncSignature:\n%@", base64String, base64SignedString];
    [output writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    NSURL *folderURL = [URL URLByDeletingLastPathComponent];
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[folderURL]];
    
    [self close];
    if (self.closedHandler) {
        self.closedHandler();
    }
}


@end
