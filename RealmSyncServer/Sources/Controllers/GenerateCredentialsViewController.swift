//
//  GenerateCredentialsViewController.swift
//  RealmSyncServer
//
//  Created by Dmitry Obukhov on 5/28/16.
//  Copyright © 2016 Realm Inc. All rights reserved.
//

import Cocoa

class GenerateCredentialsViewController: NSViewController {
    
    @IBOutlet weak var passphraseTextField: NSTextField!
    @IBOutlet weak var appBundleIDTextField: NSTextField!
    @IBOutlet weak var allowUploadCheckbox: NSButton!
    @IBOutlet weak var allowDownloadCheckbox: NSButton!
    
    let defaultPassphrase = "OutOfThePark"
    let defaultAppBundleID = "io.realm.example"
    
    var passphrase: String {
        return passphraseTextField.stringValue.characters.count > 0 ? passphraseTextField.stringValue : defaultPassphrase
    }
    
    var appBundleID: String {
        return appBundleIDTextField.stringValue.characters.count > 0 ? appBundleIDTextField.stringValue : defaultPassphrase
    }

    var allowUpload: Bool {
        return allowUploadCheckbox.state == NSOnState
    }
    
    var allowDownload: Bool {
        return allowDownloadCheckbox.state == NSOnState
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    
        passphraseTextField.placeholderString = defaultPassphrase
        appBundleIDTextField.placeholderString = defaultAppBundleID
    }
    
    private func generateCredentialsAtPath(path: String) {
        // TODO: generate credentials
        
        NSWorkspace.sharedWorkspace().activateFileViewerSelectingURLs([NSURL(fileURLWithPath: path)])
    }
    
}

extension GenerateCredentialsViewController {
    
    @IBAction func generateCredentials(sender: AnyObject?) {
        let savePanel = NSOpenPanel()
        
        savePanel.message = "Select destination directory for the authentication files"
        savePanel.prompt = "Generate"
        savePanel.canChooseDirectories = true
        savePanel.canCreateDirectories = true
        savePanel.canChooseFiles = false
        
        savePanel.beginSheetModalForWindow(view.window!) { result in
            if let path = savePanel.URL?.path where result == NSFileHandlingPanelOKButton {
                self.generateCredentialsAtPath(path)
            }
        }
    }
    
}
