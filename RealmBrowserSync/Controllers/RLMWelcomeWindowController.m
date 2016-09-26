////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

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
