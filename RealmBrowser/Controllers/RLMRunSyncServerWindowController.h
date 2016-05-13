//
//  RLMRunSyncServerWindowController.h
//  RealmBrowser
//
//  Created by Tim Oliver on 23/03/2016.
//  Copyright © 2016 Realm inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RLMRunSyncServerWindowController : NSWindowController

@property (nonatomic, weak) IBOutlet NSTextField *hostTextField;
@property (nonatomic, weak) IBOutlet NSTextField *portTextField;
@property (nonatomic, weak) IBOutlet NSTextField *realmDirectoryTextField;
@property (nonatomic, weak) IBOutlet NSButton *chooseRealmDirectoryButton;
@property (nonatomic, weak) IBOutlet NSTextField *publicTextField;
@property (nonatomic, weak) IBOutlet NSButton *choosePublicKeyButton;
@property (nonatomic, weak) IBOutlet NSButton *noReuseCheckbox;
@property (nonatomic, weak) IBOutlet NSPopUpButton *loggingLevelPopup;

@property (nonatomic, weak) IBOutlet NSButton *startServerButton;
@property (nonatomic, weak) IBOutlet NSButton *stopServerButton;

@property (nonatomic, weak) IBOutlet NSTextField *consoleOutputField;

@property (nonatomic, copy) void (^closedHandler)();

@end
