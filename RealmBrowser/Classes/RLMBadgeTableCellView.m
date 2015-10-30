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
    NSDictionary *views = NSDictionaryOfVariableBindings(textField, button, cellView);
    
    [cellView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[textField]-(10)-[button(==20@1000)]-(3)-|" options:0 metrics:nil views:views]];
    [cellView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(2)-[button(==17@250)]-(2)-|" options:0 metrics:nil views:views]];
    [cellView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(1)-[textField(==20)]" options:0 metrics:nil views:views]];
    
    return cellView;
}

@end
