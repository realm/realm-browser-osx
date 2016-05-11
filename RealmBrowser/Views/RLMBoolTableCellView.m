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

#import "RLMBoolTableCellView.h"

@implementation RLMBoolTableCellView

+ (instancetype)makeWithIdentifier:(NSString *)identifier {
    RLMBoolTableCellView *cellView = [[RLMBoolTableCellView alloc] initWithFrame:NSZeroRect];
    cellView.identifier = identifier;
    NSButton *button = [[NSButton alloc] initWithFrame:[cellView frame]];
    [button setTitle:@""];
    [button setButtonType:NSSwitchButton];
    [button setBezelStyle:0];
    cellView.checkBox = button;
    [cellView addSubview:button];
    
    [button setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [cellView addConstraint:[NSLayoutConstraint constraintWithItem:button
                                                         attribute:NSLayoutAttributeCenterX
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:cellView
                                                         attribute:NSLayoutAttributeCenterX
                                                        multiplier:1.0
                                                          constant:0.0]];
    [cellView addConstraint:[NSLayoutConstraint constraintWithItem:button
                                                         attribute:NSLayoutAttributeCenterY
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:cellView
                                                         attribute:NSLayoutAttributeCenterY
                                                        multiplier:1.0
                                                          constant:0.0]];

    return cellView;
}

@end
