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

#import "RLMTableCellView.h"

@implementation RLMTableCellView

- (NSSize)intrinsicContentSize
{
    // NSTextField's intrinsic width is always -1 for editable text fields. Temporarily disable editability so we can
    // compute the intrinsic size.
    BOOL editable = self.textField.editable;
    self.textField.editable = NO;
    NSSize size = self.textField.intrinsicContentSize;
    self.textField.editable = editable;
    return size;
}

- (RLMTextField *)realmTextField
{
    return (RLMTextField *)self.textField;
}

@end
