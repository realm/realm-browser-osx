//
//  CredentialsGenerator.swift
//  RealmSyncServer
//
//  Created by Dmitry Obukhov on 5/28/16.
//  Copyright © 2016 Realm Inc. All rights reserved.
//

import Foundation

class CredentialsGenerator {
    
    var passphrase: String
    var appID: String
    var uploadAllowed: Bool
    var downloadAllowed: Bool
    
    init(passphrase: String, appID: String, uploadAllowed: Bool, downloadAllowed: Bool) {
        self.passphrase = passphrase
        self.appID = appID
        self.uploadAllowed = uploadAllowed
        self.downloadAllowed = downloadAllowed
    }
    
    func generateCredentialsAtURL(url: NSURL) throws {
        generateKeysAtURL(url)
        
        try generateAndSignManifestAtURL(url)
    }
    
    private func generateKeysAtURL(url: NSURL) {
        let privateKeyPath = privateKeyPathForURL(url)
        let publicKeyPath = publicKeyPathForURL(url)
        
        NSTask.launchedTaskWithLaunchPath("/usr/bin/openssl", arguments: ["genrsa", "-aes256", "-passout", passphraseInput, "-out", privateKeyPath, "2048"]).waitUntilExit()
        
        NSTask.launchedTaskWithLaunchPath("/usr/bin/openssl", arguments: ["rsa", "-in", privateKeyPath, "-outform", "PEM", "-passin", passphraseInput, "-pubout", "-out", publicKeyPath]).waitUntilExit()
    }
    
    private func generateAndSignManifestAtURL(url: NSURL) throws {
        var access: [String] = []
        
        if uploadAllowed {
            access.append("upload")
        }
        
        if downloadAllowed {
            access.append("download")
        }
        
        var manifest: [String: AnyObject] = [:]
        
        manifest["identity"] = NSUUID().UUIDString
        manifest["access"] = access
        manifest["app_id"] = appID
        
        let manifestData = try NSJSONSerialization.dataWithJSONObject(manifest, options: .PrettyPrinted)
        
        manifestData.writeToURL(url.URLByAppendingPathComponent("manifest.json"), atomically: true)
        
        let inputPipe = NSPipe()
        let outputPipe = NSPipe()
        
        let signTask = NSTask()
        
        signTask.launchPath = "/usr/bin/openssl"
        signTask.arguments = ["dgst", "-sha256", "-binary", "-passin", passphraseInput, "-sign", privateKeyPathForURL(url)]
        signTask.standardInput = inputPipe
        signTask.standardOutput = outputPipe
        
        inputPipe.fileHandleForWriting.writeData(manifestData)
        inputPipe.fileHandleForWriting.closeFile()
        
        signTask.launch()
        signTask.waitUntilExit()
        
        let signedManifestData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        
        let base64ManifestString = manifestData.base64EncodedStringWithOptions([])
        let base64SignedManifestString = signedManifestData.base64EncodedStringWithOptions([])
        
        try "Signed User Token:\n\(base64ManifestString):\(base64SignedManifestString)".writeToURL(url.URLByAppendingPathComponent("Credentials.txt"), atomically: true, encoding: NSUTF8StringEncoding)
    }
    
    private var passphraseInput: String {
        return "pass:\(passphrase)"
    }
    
    private func privateKeyPathForURL(url: NSURL) -> String {
        return url.URLByAppendingPathComponent("private.pem").path!
    }
    
    private func publicKeyPathForURL(url: NSURL) -> String {
        return url.URLByAppendingPathComponent("public.pem").path!
    }
    
}
