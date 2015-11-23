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

#import "RLMAlert.h"

@implementation RLMAlert

+ (BOOL)showEncryptionConfirmationDialogWithFileName:(NSString *)fileName
{
    NSAlert *encryptionAlert = [[NSAlert alloc] init];
    encryptionAlert.messageText = [NSString stringWithFormat:@"'%@' could not be opened. It may be encrypted, or it isn't in a compatible file format.", fileName];
    encryptionAlert.informativeText = @"If you know the file is encrypted, you can manually enter its encryption key to open it.";
    [encryptionAlert addButtonWithTitle:@"Close"];
    [encryptionAlert addButtonWithTitle:@"Enter Encryption Key"];
    
    return ([encryptionAlert runModal] == NSAlertSecondButtonReturn);
}

+ (BOOL)showFileFormatUpgradeDialogWithFileName:(NSString *)fileName
{
    NSAlert *upgradeAlert = [[NSAlert alloc] init];
    upgradeAlert.messageText = [NSString stringWithFormat:@"'%@' is at an older file format version and must be upgraded before it can be opened. Would you like to proceed?", fileName];
    upgradeAlert.informativeText = @"If the file is upgraded, it will no longer be compatible with older versions of Realm. File format upgrades are permanent and cannot be undone.";
    [upgradeAlert addButtonWithTitle:@"Cancel"];
    [upgradeAlert addButtonWithTitle:@"Proceed with Upgrade"];
    
    return [upgradeAlert runModal] == NSAlertSecondButtonReturn;
}

@end
