//
//  ColorView.swift
//  RealmSyncServer
//
//  Created by Dmitry Obukhov on 5/27/16.
//  Copyright © 2016 Realm Inc. All rights reserved.
//

import Cocoa

class ColorView: NSView {
    
    @IBInspectable var color: NSColor = NSColor.whiteColor()

    override func drawRect(dirtyRect: NSRect) {
        color.setFill()
        NSRectFillUsingOperation(dirtyRect, .CompositeSourceOver)
    }
    
}
