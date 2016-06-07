////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014-2015 Realm Inc.
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

#import "RLMOptionalBoolTableCellView.h"
#import "RLMBrowserConstants.h"
#import "NSColor+ByteSizeFactory.h"

@interface RLMOptionalBoolTableCellView ()

@property (nonatomic, strong, readwrite) NSPopUpButton *popupControl;

@end

@implementation RLMOptionalBoolTableCellView

- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    
    if (self == nil) {
        return nil;
    }
    
    NSPopUpButton *popupButton = [[NSPopUpButton alloc] initWithFrame:self.bounds pullsDown:NO];
    popupButton.translatesAutoresizingMaskIntoConstraints = NO;
    [popupButton addItemsWithTitles:@[@"nil", @"false", @"true"]];
    popupButton.bordered = NO;
    self.popupControl = popupButton;
    [self addSubview:popupButton];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.popupControl
                                                     attribute:NSLayoutAttributeWidth
                                                     relatedBy:NSLayoutRelationLessThanOrEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeWidth
                                                    multiplier:1.0
                                                      constant:0.0]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.popupControl
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1.0
                                                      constant:0.0]];
    
    return self;
}

@end
