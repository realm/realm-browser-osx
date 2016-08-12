//
//  RLMSyncServerBrowserWindowController.h
//  RealmBrowser
//
//  Created by Dmitry Obukhov on 11/08/16.
//  Copyright © 2016 Realm inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RLMSyncServerBrowserWindowController : NSWindowController

@property (nonatomic, strong, readonly) NSString *selectedRealmPath;

- (NSModalResponse)connectToServerAtURL:(NSURL *)url accessToken:(NSString *)token error:(NSError **)error;

@end
