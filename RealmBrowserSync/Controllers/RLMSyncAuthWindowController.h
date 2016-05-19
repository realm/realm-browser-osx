//
//  RLMSyncAuthWindowController.h
//  RealmBrowser
//
//  Created by Tim Oliver on 30/03/2016.
//  Copyright © 2016 Realm inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RLMSyncAuthWindowController : NSWindowController

@property (nonatomic, weak) IBOutlet NSTextField *passPhraseTextField;
@property (nonatomic, weak) IBOutlet NSTextField *appBundleTextField;
@property (nonatomic, weak) IBOutlet NSButton *uploadAccessButton;
@property (nonatomic, weak) IBOutlet NSButton *downloadAccessButton;
@property (nonatomic, weak) IBOutlet NSButton *cancelButton;
@property (nonatomic, weak) IBOutlet NSButton *proceedButton;

@property (nonatomic, copy) void (^closedHandler)();

@end
