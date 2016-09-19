//
//  RLMDocumentController.m
//  RealmBrowser
//
//  Created by Dmitry Obukhov on 24/08/16.
//  Copyright © 2016 Realm inc. All rights reserved.
//

@import Realm;

#import "RLMDocumentController.h"
#import "RLMDocument.h"
#import "RLMBrowserConstants.h"

@implementation RLMDocumentController

- (void)openDocumentWithContentsOfSyncURL:(NSURL *)url credential:(RLMSyncCredential *)credential authServerURL:(NSURL *)authServerURL display:(BOOL)displayDocument completionHandler:(void (^)(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error))completionHandler; {
    RLMDocument *document = [self documentForURL:url];

    if (document != nil) {
        completionHandler(document, YES, nil);
        return;
    }

    NSError *error;
    document = [[RLMDocument alloc] initWithContentsOfSyncURL:url credential:credential authServerURL:authServerURL error:&error];

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
