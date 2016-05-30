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
    let defaultAppBundleID = "io.realm.Example"
    
    var passphrase: String {
        return passphraseTextField.stringValue.characters.count > 0 ? passphraseTextField.stringValue : defaultPassphrase
    }
    
    var appBundleID: String {
        return appBundleIDTextField.stringValue.characters.count > 0 ? appBundleIDTextField.stringValue : defaultAppBundleID
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
    
    private func generateCredentialsAtURL(url: NSURL) {
        let credentialsGenerator = CredentialsGenerator(passphrase: passphrase, appID: appBundleID, uploadAllowed: allowUpload, downloadAllowed: allowDownload)
        
        do {
            try credentialsGenerator.generateCredentialsAtURL(url)
            
            NSWorkspace.sharedWorkspace().activateFileViewerSelectingURLs([url])
        } catch let error as NSError {
            let alert = NSAlert(error: error)
            
            if let window = view.window {
                alert.beginSheetModalForWindow(window, completionHandler: nil)
            } else {
                alert.runModal()
            }
        }
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
            if let url = savePanel.URL where result == NSFileHandlingPanelOKButton {
                self.generateCredentialsAtURL(url)
            }
        }
    }
    
}
