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

@import Realm;

#import "RLMDocumentController.h"
#import "RLMDocument.h"
#import "RLMBrowserConstants.h"

@implementation RLMDocumentController

- (void)openDocumentWithContentsOfSyncURL:(NSURL *)url credentials:(RLMSyncCredentials *)credentials authServerURL:(NSURL *)authServerURL display:(BOOL)displayDocument completionHandler:(void (^)(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error))completionHandler; {
    RLMDocument *document = [self documentForURL:url];

    if (document != nil) {
        completionHandler(document, YES, nil);
        return;
    }

    NSError *error;
    document = [[RLMDocument alloc] initWithContentsOfSyncURL:url credentials:credentials authServerURL:authServerURL error:&error];

    if (document != nil) {
        [self addDocument:document];

        if (displayDocument) {
            [document makeWindowControllers];
            [document showWindows];
        }
    }

    // NSDocumentController calls completion handler asynchronously for new documents
    dispatch_async(dispatch_get_main_queue(), ^{
        completionHandler(document, NO, error);
    });
}

- (NSString *)typeForContentsOfURL:(NSURL *)url error:(NSError * _Nullable __autoreleasing *)outError {
    if ([url.scheme isEqualToString:kRealmURLScheme] || [url.scheme isEqualToString:kSecureRealmURLScheme]) {
        return kRealmUTIIdentifier;
    } else {
        return [super typeForContentsOfURL:url error:outError];
    }
}

- (void)openDocument:(id)sender {
    @try {
        [super openDocument:sender];
    } @catch (NSException *exception) {
        // NSOpenPanel in sandboxed environment doesn't handle changes in path and crashes if one of the parent directories has been renamed.
        // This case usually happens when users try to open realm file from simulator's directory while Xcode launches an app and changes
        // simulator root path.
        // See https://rink.hockeyapp.net/manage/apps/405793/app_versions/27/crash_reasons/176155071.
        NSAlert *alert = [NSAlert alertWithMessageText:@"Failed to open realm file" defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:@"File has been moved to a different location, please try to open it again."];
        [alert runModal];
    }
}

@end
