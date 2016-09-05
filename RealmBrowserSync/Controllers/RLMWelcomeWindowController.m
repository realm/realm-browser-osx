//
//  RLMWelcomeWindowController.m
//  RealmBrowser
//
//  Created by Dmitry Obukhov on 02/09/16.
//  Copyright © 2016 Realm inc. All rights reserved.
//

#import "RLMWelcomeWindowController.h"
#import "RLMApplicationDelegate.h"

@interface RLMWelcomeWindowController ()

@property (nonatomic, weak) IBOutlet NSTextField *versionLabel;

@end

@implementation RLMWelcomeWindowController

- (void)windowDidLoad {
    [super windowDidLoad];

    self.window.backgroundColor = [NSColor whiteColor];
    self.window.titlebarAppearsTransparent = YES;
    self.window.movableByWindowBackground = YES;

    [[self.window standardWindowButton:NSWindowMiniaturizeButton] setHidden:YES];
    [[self.window standardWindowButton:NSWindowZoomButton] setHidden:YES];

    self.versionLabel.stringValue = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

- (IBAction)openRealmFile:(id)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSDocumentController sharedDocumentController] openDocument:sender];
    });

    [self close];
}

- (IBAction)openRealmURL:(id)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        [(RLMApplicationDelegate *)NSApp.delegate openSyncURL:sender];
    });

    [self close];
}

- (IBAction)connecToServer:(id)sender {
    [self close];

    dispatch_async(dispatch_get_main_queue(), ^{
        [(RLMApplicationDelegate *)NSApp.delegate connectToSyncServer:sender];
    });
}

- (void)cancel:(id)sender {
    [self close];
}

@end
