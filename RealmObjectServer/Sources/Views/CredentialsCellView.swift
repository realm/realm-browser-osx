//
//  CredentialsCellView.swift
//  RealmSyncServer
//
//  Created by Dmitry Obukhov on 03/06/16.
//  Copyright © 2016 Realm Inc. All rights reserved.
//

import Cocoa

class CredentialsCellView: NSTableCellView {

    @IBOutlet weak var identityLabel: NSTextField!
    
    private var token: String?
    
    func configureWithCredentials(credentials: Credentials) {
        identityLabel.stringValue = credentials.identity
        token = credentials.token
    }
    
    @IBAction func copyToken(sender: AnyObject?) {
        if let token = token {
            NSPasteboard.generalPasteboard().clearContents()
            NSPasteboard.generalPasteboard().setString(token, forType: NSPasteboardTypeString)
        }
    }
    
}
