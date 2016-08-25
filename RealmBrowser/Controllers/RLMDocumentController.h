//
//  RLMDocumentController.h
//  RealmBrowser
//
//  Created by Dmitry Obukhov on 24/08/16.
//  Copyright © 2016 Realm inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RLMDocumentController : NSDocumentController

- (void)openDocumentWithContentsOfSyncURL:(NSURL *)url credential:(RLMCredential *)credential display:(BOOL)displayDocument completionHandler:(void (^)(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error))completionHandler;

@end
