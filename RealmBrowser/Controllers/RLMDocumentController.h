//
//  RLMDocumentController.h
//  RealmBrowser
//
//  Created by Dmitry Obukhov on 24/08/16.
//  Copyright © 2016 Realm inc. All rights reserved.
//

@import Cocoa;

NS_ASSUME_NONNULL_BEGIN

@interface RLMDocumentController : NSDocumentController

- (void)openDocumentWithContentsOfSyncURL:(NSURL *)url credential:(RLMCredential *)credential display:(BOOL)displayDocument completionHandler:(void (^)(NSDocument * __nullable document, BOOL documentWasAlreadyOpen, NSError * __nullable error))completionHandler;

@end

NS_ASSUME_NONNULL_END
