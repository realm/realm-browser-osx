//
//  RLMCredentialsWindowController.m
//  RealmBrowser
//
//  Created by Dmitry Obukhov on 29/08/16.
//  Copyright © 2016 Realm inc. All rights reserved.
//

#import "RLMCredentialsWindowController.h"
#import "RLMCredentialsViewController.h"
#import "NSView+RLMExtensions.h"

@interface RLMCredentialsWindowController ()

@property (nonatomic, weak) IBOutlet NSTextField *messageLabel;
@property (nonatomic, weak) IBOutlet NSView *credentialsContainerView;

@property (nonatomic, strong) RLMCredentialsViewController *credentialsViewController;

@end

@implementation RLMCredentialsWindowController

- (instancetype)initWithSyncURL:(NSURL *)syncURL; {
    self = [super init];

    if (self != nil) {
        self.credentialsViewController = [[RLMCredentialsViewController alloc] initWithSyncURL:syncURL];
    }

    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];

    [self.credentialsContainerView addContentSubview:self.credentialsViewController.view];
}

- (NSString *)message {
    return self.messageLabel.stringValue;
}

- (void)setMessage:(NSString *)message {
    self.messageLabel.stringValue = message;
}

- (RLMCredential *)credential {
    return self.credentialsViewController.credential;
}

- (void)setCredential:(RLMCredential *)credential {
    self.credentialsViewController.credential = credential;
}

- (IBAction)ok:(id)sender {
    [self closeWithReturnCode:NSModalResponseOK];
}

- (IBAction)cancel:(id)sender {
    [self closeWithReturnCode:NSModalResponseCancel];
}

@end
