//
//  RLMSyncURLValueTransformer.m
//  RealmBrowser
//
//  Created by Dmitry Obukhov on 29/08/16.
//  Copyright © 2016 Realm inc. All rights reserved.
//

#import "RLMSyncURLValueTransformer.h"

@implementation RLMSyncURLValueTransformer

+ (Class)transformedValueClass {
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (nullable id)transformedValue:(nullable id)value {
    NSURL *url = value;

    return url.absoluteString;
}

- (nullable id)reverseTransformedValue:(nullable id)value {
    return [NSURL URLWithString:value];
}

@end