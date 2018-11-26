////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

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
    NSString *urlString = value;

    if (urlString && ![urlString containsString:@"://"]) {
        urlString = [@"realm://" stringByAppendingString:urlString];
    }

    return [NSURL URLWithString:urlString];
}

@end
