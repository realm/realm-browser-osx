//
//  RLMConnectionIndicatorWindowController.m
//  RealmBrowser
//
//  Created by Dmitry Obukhov on 31/08/16.
//  Copyright © 2016 Realm inc. All rights reserved.
//

#import "RLMConnectionIndicatorWindowController.h"

@interface RLMConnectionIndicatorWindowController ()

@property (nonatomic, weak) IBOutlet NSTextField *messageLabel;
@property (nonatomic, weak) IBOutlet NSProgressIndicator *progressIndicator;

@end

@implementation RLMConnectionIndicatorWindowController

- (void)showWindow:(id)sender {
    [super showWindow:sender];

    [self.progressIndicator startAnimation:nil];
}

- (NSString *)message {
    return self.messageLabel.stringValue;
}

- (void)setMessage:(NSString *)message {
    self.messageLabel.stringValue = message;
}

@end
