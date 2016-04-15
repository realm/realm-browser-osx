//
//  RLMSyncCredentialsView.h
//  RealmBrowser
//
//  Created by Tim Oliver on 11/02/2016.
//  Copyright © 2016 Realm inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RLMSyncCredentialsView : NSView

@property (nonatomic, weak) IBOutlet NSTextField *syncServerURLField;
@property (nonatomic, weak) IBOutlet NSTextField *syncIdentityField;
@property (nonatomic, weak) IBOutlet NSTextField *syncSignatureField;

@end
