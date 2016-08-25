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

- (void)openDocumentWithContentsOfSyncURL:(NSURL *)url credential:(RLMCredential *)credential display:(BOOL)displayDocument completionHandler:(void (^)(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error))completionHandler {
    // TODO: handle documentWasAlreadyOpen properly

    NSError *error;
    RLMDocument *document = [[RLMDocument alloc] initWithContentsOfSyncURL:url credential:credential error:&error];

    if (error != nil) {
        // TODO: handle error
        return;
    }

    [self addDocument:document];

    if (displayDocument) {
        [document makeWindowControllers];
        [document showWindows];
    }

    // TODO: call completion handler
    completionHandler(document, NO, error);
}

- (NSString *)typeForContentsOfURL:(NSURL *)url error:(NSError * _Nullable __autoreleasing *)outError {
    if ([url.scheme isEqualToString:@"realm"] || [url.scheme isEqualToString:@"realms"]) {
        return kRealmUTIIdentifier;
    } else {
        return [super typeForContentsOfURL:url error:outError];
    }
}

@end
