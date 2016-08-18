//
//  RLMSyncCredentialsWindowController+Private.h
//  RealmBrowser
//
//  Created by Dmitry Obukhov on 16/08/16.
//  Copyright © 2016 Realm inc. All rights reserved.
//

#import "RLMSyncCredentialsWindowController.h"

@interface RLMSyncCredentialsWindowController () <NSWindowDelegate>

@property (weak) IBOutlet NSTextField *urlLabel;
@property (weak) IBOutlet NSTextField *urlTextField;

@property (weak) IBOutlet NSTextField *tokenLabel;
@property (weak) IBOutlet NSTextField *tokenTextField;

@property (weak) IBOutlet NSButton *okButton;
@property (weak) IBOutlet NSButton *cancelButton;

- (void)updateUI;

@end
