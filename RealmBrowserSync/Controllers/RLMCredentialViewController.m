//
//  RLMCredentialViewController.m
//  RealmBrowser
//
//  Created by Dmitry Obukhov on 31/08/16.
//  Copyright © 2016 Realm inc. All rights reserved.
//

#import "RLMCredentialViewController.h"
#import "RLMCredentialViewController+Private.h"

static NSString * const RLMCredentialViewControllerClassPrefix = @"RLM";
static NSString * const RLMCredentialViewControllerClassSyffix = @"Controller";

@implementation RLMCredentialViewController

+ (NSString *)defaultNibName {
    NSString* nibName = NSStringFromClass(self);

    if ([nibName hasPrefix:RLMCredentialViewControllerClassPrefix]) {
        nibName = [nibName substringFromIndex:RLMCredentialViewControllerClassPrefix.length];
    }

    if ([nibName hasSuffix:RLMCredentialViewControllerClassSyffix]) {
        nibName = [nibName substringToIndex:nibName.length - RLMCredentialViewControllerClassSyffix.length];
    }

    return nibName;
}

- (instancetype)initWithServerURL:(NSURL *)serverURL credential:(RLMCredential *)credential {
    self = [super initWithNibName:[self.class defaultNibName] bundle:nil];

    if (self != nil) {
        self.serverURL = serverURL;
        self.credential = credential;
    }

    return self;
}

@end
