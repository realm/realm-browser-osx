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

#import "RLMLinkTableCellView.h"
#import "NSColor+ByteSizeFactory.h"

@implementation RLMLinkTableCellView

+ (instancetype)makeWithIdentifier:(NSString *)identifier
{
    RLMLinkTableCellView *cellView = [[RLMLinkTableCellView alloc] initWithFrame:NSZeroRect];
    cellView.identifier = identifier;
    NSTextField *textField = [[NSTextField alloc] initWithFrame:[cellView frame]];
    [textField setBordered:NO];
    [textField setDrawsBackground:NO];
    [textField setTextColor:[NSColor selectedMenuItemTextColor]];
    cellView.textField = textField;
    [cellView addSubview:textField];
    
    [textField setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [cellView addConstraint:[NSLayoutConstraint constraintWithItem:textField
                                                         attribute:NSLayoutAttributeLeading
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:cellView
                                                         attribute:NSLayoutAttributeLeading
                                                        multiplier:1.0
                                                          constant:0.0]];
    [cellView addConstraint:[NSLayoutConstraint constraintWithItem:textField
                                                         attribute:NSLayoutAttributeTrailing
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:cellView
                                                         attribute:NSLayoutAttributeTrailing
                                                        multiplier:1.0
                                                          constant:0.0]];
    
    [cellView addConstraint:[NSLayoutConstraint constraintWithItem:textField
                                                         attribute:NSLayoutAttributeTop
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:cellView
                                                         attribute:NSLayoutAttributeTop
                                                        multiplier:1.0
                                                          constant:0.0]];
    [cellView addConstraint:[NSLayoutConstraint constraintWithItem:textField
                                                         attribute:NSLayoutAttributeBottom
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:cellView
                                                         attribute:NSLayoutAttributeBottom
                                                        multiplier:1.0
                                                          constant:0.0]];
    
    return cellView;
}

- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle {
    [super setBackgroundStyle:backgroundStyle];
    self.textField.textColor = (backgroundStyle == NSBackgroundStyleLight ? [NSColor linkColor] : [NSColor whiteColor]);
}

@end
