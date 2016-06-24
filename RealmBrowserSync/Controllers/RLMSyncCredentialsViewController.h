//
//  RLMSyncCredentialsViewController.h
//  RealmBrowser
//
//  Created by Dmitry Obukhov on 13/06/16.
//  Copyright © 2016 Realm inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RLMSyncCredentialsViewController : NSViewController <NSOpenSavePanelDelegate>

@property (copy) NSURL *syncServerURL;
@property (copy) NSString *signedUserToken;

- (BOOL)validateCredentials:(NSError *__autoreleasing *)error;

@end
