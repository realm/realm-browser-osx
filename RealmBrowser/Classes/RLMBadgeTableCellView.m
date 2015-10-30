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

#import "RLMBadgeTableCellView.h"

@implementation RLMBadgeTableCellView

+ (instancetype)makeWithIdentifier:(NSString *)identifier
{
    RLMBadgeTableCellView *cellView = [[RLMBadgeTableCellView alloc] initWithFrame:NSZeroRect];
    cellView.identifier = identifier;
    NSTextField *textField = [[NSTextField alloc] initWithFrame:[cellView frame]];
    [textField setBordered:NO];
    [textField setDrawsBackground:NO];
    [textField setTextColor:[NSColor selectedMenuItemTextColor]];
    cellView.textField = textField;
    [cellView addSubview:textField];
    NSButton *button = [[NSButton alloc] initWithFrame:NSZeroRect];
    [button setButtonType:NSMomentaryPushInButton];
    [button setBezelStyle:NSInlineBezelStyle];
    cellView.badge = button;
    [cellView addSubview:button];
    
    [textField setTranslatesAutoresizingMaskIntoConstraints:NO];
    [button setTranslatesAutoresizingMaskIntoConstraints:NO];

    [cellView addConstraint:[NSLayoutConstraint constraintWithItem:textField
                                                         attribute:NSLayoutAttributeLeading
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:cellView
                                                         attribute:NSLayoutAttributeLeading
                                                        multiplier:1.0
                                                          constant:0.0]];
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:textField
                                                                 attribute:NSLayoutAttributeTrailing
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:button
                                                                 attribute:NSLayoutAttributeLeading
                                                                multiplier:1.0
                                                                  constant:20.0];
    [constraint setPriority:NSLayoutPriorityRequired];
    [cellView addConstraint:constraint];
    [cellView addConstraint:[NSLayoutConstraint constraintWithItem:button
                                                         attribute:NSLayoutAttributeTrailing
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:cellView
                                                         attribute:NSLayoutAttributeTrailing
                                                        multiplier:1.0
                                                          constant:-3.0]];
    
    
    constraint = [NSLayoutConstraint constraintWithItem:button
                                                                  attribute:NSLayoutAttributeWidth
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:nil
                                                                  attribute:0
                                                                 multiplier:1.0
                                                                   constant:20.0];
    [constraint setPriority:NSLayoutPriorityRequired];
    [cellView addConstraint:constraint];
    
    
    [cellView addConstraint:[NSLayoutConstraint constraintWithItem:button
                                                         attribute:NSLayoutAttributeCenterY
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:cellView
                                                         attribute:NSLayoutAttributeCenterY
                                                        multiplier:1.0
                                                          constant:0.0]];
    [cellView addConstraint:[NSLayoutConstraint constraintWithItem:textField
                                                         attribute:NSLayoutAttributeCenterY
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:cellView
                                                         attribute:NSLayoutAttributeCenterY
                                                        multiplier:1.0
                                                          constant:0.0]];
    
    return cellView;
}

@end
