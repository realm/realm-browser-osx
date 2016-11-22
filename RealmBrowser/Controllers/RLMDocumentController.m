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

@end
