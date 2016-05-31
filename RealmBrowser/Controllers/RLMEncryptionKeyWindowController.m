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

@import Realm;
@import Realm.Dynamic;
@import Realm.Private;

#import "RLMEncryptionKeyWindowController.h"
#import "RLMAlert.h"

@interface RLMEncryptionKeyWindowController () <NSTextFieldDelegate>

@property (nonatomic, strong) NSURL *realmFilePath;
@property (nonatomic, strong, readwrite) NSData *encryptionKey;

- (BOOL)testRealmFileWithEncryptionKey:(NSData *)keyData;
- (NSData *)dataFromHexadecimalString:(NSString *)string;

@end

@implementation RLMEncryptionKeyWindowController

- (instancetype)initWithRealmFilePath:(NSURL *)realmFilePath
{
    if (self = [super initWithWindowNibName:@"EncryptionKeyWindow"]) {
        _realmFilePath = realmFilePath;
    }
    
    return self;
}

- (void)controlTextDidChange:(NSNotification *)notification {
    NSString *stringValue = self.keyTextField.stringValue;
    
    //Ensure only hex-compatible characters have been entered
    NSCharacterSet *chars = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789ABCDEFabcdef"] invertedSet];
    BOOL isValid = (NSNotFound == [stringValue rangeOfCharacterFromSet:chars].location) && stringValue.length == 128;
    self.okayButton.enabled = isValid;
}

- (IBAction)okayButtonClicked:(id)sender
{
    NSData *encryptionKey = [self dataFromHexadecimalString:self.keyTextField.stringValue];
    if ([self testRealmFileWithEncryptionKey:encryptionKey] == NO) {
        self.errorTextField.hidden = NO;
        return;
    }
    
    self.encryptionKey = encryptionKey;
    
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
}

- (IBAction)cancelButtonClicked:(id)sender
{
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
}

#pragma mark - Encryption Testing -
- (BOOL)testRealmFileWithEncryptionKey:(NSData *)keyData
{
    NSError *error = nil;
    @autoreleasepool {
        RLMRealmConfiguration *configuration = [[RLMRealmConfiguration alloc] init];
        configuration.disableFormatUpgrade = YES;
        configuration.dynamic = YES;
        configuration.encryptionKey = keyData;
        configuration.fileURL = self.realmFilePath;
        [RLMRealm realmWithConfiguration:configuration error:&error];
    }
    
    //If an error is thrown, it can either mean the encryption key was incorrect,
    //or the file format requires upgrading
    if (error) {
        //If a format upgrade is required, prompt the user before proceeding
        if (error.code == RLMErrorFileFormatUpgradeRequired) {
            if (![RLMAlert showFileFormatUpgradeDialogWithFileName:[self.realmFilePath lastPathComponent]]) {
                return NO;
            }
            
            //The file format upgrade is allowed
            return YES;
        }
        
        //another error was thrown, which implies that the encryption key was invalid
        return NO;
    }
    
    return YES;
}

// http://stackoverflow.com/a/13627835/599344
- (NSData *)dataFromHexadecimalString:(NSString *)string
{
    string = [string lowercaseString];
    NSMutableData *data= [NSMutableData new];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i = 0;
    NSInteger length = string.length;
    while (i < length-1) {
        char c = [string characterAtIndex:i++];
        if (c < '0' || (c > '9' && c < 'a') || c > 'f')
            continue;
        byte_chars[0] = c;
        byte_chars[1] = [string characterAtIndex:i++];
        whole_byte = strtol(byte_chars, NULL, 16);
        [data appendBytes:&whole_byte length:1];
    }
    return data;
}

@end
