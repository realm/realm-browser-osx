//
//  RLMSyncCredentialsView.m
//  RealmBrowser
//
//  Created by Tim Oliver on 11/02/2016.
//  Copyright © 2016 Realm inc. All rights reserved.
//

#import "RLMSyncCredentialsView.h"

@implementation RLMSyncCredentialsView

- (void)viewDidMoveToSuperview
{
    [super viewDidMoveToSuperview];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *serverURL = [defaults stringForKey:@"SyncServerURL"];
    if (serverURL.length > 0) {
        self.syncServerURLField.stringValue = serverURL;
    }
    
    NSString *userToken = [defaults stringForKey:@"SyncSignedUserToken"];
    if (userToken.length > 0) {
        self.syncSignedUserTokenField.stringValue = userToken;
    }
}

@end
