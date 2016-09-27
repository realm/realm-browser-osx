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

#import "RLMCredentialsWindowController.h"
#import "RLMCredentialsViewController.h"
#import "NSView+RLMExtensions.h"

@interface RLMCredentialsWindowController ()

@property (nonatomic, weak) IBOutlet NSTextField *messageLabel;
@property (nonatomic, weak) IBOutlet NSView *credentialsContainerView;

@property (nonatomic, strong) RLMCredentialsViewController *credentialsViewController;

@end

@implementation RLMCredentialsWindowController

- (instancetype)init {
    self = [super init];

    if (self != nil) {
        self.credentialsViewController = [[RLMCredentialsViewController alloc] init];
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

- (RLMSyncCredential *)credential {
    return self.credentialsViewController.credential;
}

- (void)setCredential:(RLMSyncCredential *)credential {
    self.credentialsViewController.credential = credential;
}

- (IBAction)ok:(id)sender {
    if (self.credential != nil) {
        [self closeWithReturnCode:NSModalResponseOK];
    }
}

- (IBAction)cancel:(id)sender {
    [self closeWithReturnCode:NSModalResponseCancel];
}

@end
