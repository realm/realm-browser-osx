//
//  NSURLComponents+FragmentItems.m
//
//  Copyright 2016 Timothy Oliver. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
//  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "NSURLComponents+FragmentItems.h"

@implementation NSURLComponents (FragmentItems)

@dynamic fragmentItems;

- (NSArray<NSURLQueryItem *> *)fragmentItems
{
    NSString *fragment = self.fragment;
    if (fragment.length == 0) {
        return nil;
    }
    
    NSMutableArray<NSURLQueryItem *> *items = [NSMutableArray array];
    NSArray *fragmentComponenents = [fragment componentsSeparatedByString:@"&"];
    for (NSString *fragment in fragmentComponenents) {
        //Assuming a value of 'key=value' for each component, parse the two separate components
        NSArray *keyValues = [fragment componentsSeparatedByString:@"="];
        if (keyValues.count != 2) {
            continue;
        }
        
        NSString *keyName = keyValues.firstObject;
        NSString *value = [keyValues.lastObject stringByRemovingPercentEncoding];
        
        NSURLQueryItem *item = [NSURLQueryItem queryItemWithName:keyName value:value];
        [items addObject:item];
    }
    
    if (fragmentComponenents.count == 0) {
        return nil;
    }
    
    return [NSArray arrayWithArray:items];
}

- (void)setFragmentItems:(NSArray<NSURLQueryItem *> *)fragmentItems
{
    //If this instance is non-mutable
    if ([self respondsToSelector:@selector(setFragment:)] == NO) {
        return;
    }
    
    if (fragmentItems.count == 0) {
        return;
    }
    
    NSString *fragmentString = @"";
    for (NSURLQueryItem *item in fragmentItems) {
        NSString *encodedName = [item.name stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        NSString *encodedValue = [item.value stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        
        //preprend '&' if this isn't the first value in the string
        if (fragmentString.length > 0) {
            fragmentString = [fragmentString stringByAppendingString:@"&"];
        }
        
        NSString *component = [NSString stringWithFormat:@"%@=%@", encodedName, encodedValue];
        fragmentString = [fragmentString stringByAppendingString:component];
    }
    
    self.fragment = fragmentString;
}

#pragma mark - Dictionary -
- (NSDictionary *)fragmentItemsDictionary
{
    // Copy the fragments to a dictionary
    NSArray *fragmentItems = self.fragmentItems;
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    for (NSURLQueryItem *item in fragmentItems) {
        dictionary[item.name] = item.value;
    }
    
    //Make immutable
    return [NSDictionary dictionaryWithDictionary:dictionary];
}

- (void)setFragmentItemsDictionary:(NSDictionary *)fragmentItemsDictionary
{
    NSMutableArray *array = [NSMutableArray array];
    for (NSString *key in fragmentItemsDictionary.allKeys) {
        [array addObject:[NSURLQueryItem queryItemWithName:key value:fragmentItemsDictionary[key]]];
    }
    
    self.fragmentItems = array;
}

@end
