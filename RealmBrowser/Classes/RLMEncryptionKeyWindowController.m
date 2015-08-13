////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014-2015 Realm Inc.
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

#import "RLMEncryptionKeyWindowController.h"

@interface RLMEncryptionKeyWindowController ()

@property (nonatomic, strong) NSURL *realmFilePath;

@end

@implementation RLMEncryptionKeyWindowController

- (instancetype)initWithRealmFilePath:(NSURL *)realmFilePath
{
    if (self = [super initWithWindowNibName:@"EncryptionKeyWindow"]) {
        _realmFilePath = realmFilePath;
    }
    
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
}

- (IBAction)okayButtonClicked:(id)sender
{
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
}

- (IBAction)cancelButtonClicked:(id)sender
{
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
}

@end
