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

#import "RLMCredentialViewController.h"
#import "RLMCredentialViewController+Private.h"

static NSString * const RLMCredentialViewControllerClassPrefix = @"RLM";
static NSString * const RLMCredentialViewControllerClassSyffix = @"Controller";

@implementation RLMCredentialViewController

+ (NSString *)defaultNibName {
    NSString* nibName = NSStringFromClass(self);

    if ([nibName hasPrefix:RLMCredentialViewControllerClassPrefix]) {
        nibName = [nibName substringFromIndex:RLMCredentialViewControllerClassPrefix.length];
    }

    if ([nibName hasSuffix:RLMCredentialViewControllerClassSyffix]) {
        nibName = [nibName substringToIndex:nibName.length - RLMCredentialViewControllerClassSyffix.length];
    }

    return nibName;
}

- (instancetype)init {
    return [self initWithNibName:[self.class defaultNibName] bundle:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    for (NSTextField *textField in [self textFieldsForCredentials]) {
        textField.delegate = self;
    }
}

- (NSArray *)textFieldsForCredentials {
    return nil;
}

#pragma mark - NSTextFieldDelegate

- (void)controlTextDidChange:(NSNotification *)obj {
    // Trigger KVO notification for credential
    [self willChangeValueForKey:@"credential"];
    [self didChangeValueForKey:@"credential"];
}

@end
