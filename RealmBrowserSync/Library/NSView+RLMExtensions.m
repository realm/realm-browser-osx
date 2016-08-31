//
//  NSView+RLMExtensions.m
//  RealmBrowser
//
//  Created by Dmitry Obukhov on 31/08/16.
//  Copyright © 2016 Realm inc. All rights reserved.
//

#import "NSView+RLMExtensions.h"

@implementation NSView (RLMExtensions)

- (void)addContentSubview:(NSView *)contentSubview {
    contentSubview.translatesAutoresizingMaskIntoConstraints = NO;

    NSDictionary *views = NSDictionaryOfVariableBindings(contentSubview);

    [self addSubview:contentSubview];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[contentSubview]|" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[contentSubview]|" options:0 metrics:nil views:views]];
}

@end
