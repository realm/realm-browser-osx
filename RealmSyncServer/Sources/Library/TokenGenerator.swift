//
//  TokenGenerator.swift
//  RealmSyncServer
//
//  Created by Dmitry Obukhov on 01/06/16.
//  Copyright © 2016 Realm Inc. All rights reserved.
//

import Foundation

class TokenGenerator {
    
    let privateKeyURL: NSURL
    let passphrase: String
    
    init(privateKeyURL: NSURL, passphrase: String) {
        self.privateKeyURL = privateKeyURL
        self.passphrase = passphrase
    }
    
    func generateTokenForJSONObject(object: JSONRepresentable) throws -> String {
        let manifestData = try NSJSONSerialization.dataWithJSONObject(object.JSONRepresentation, options: .PrettyPrinted)
        
        let inputPipe = NSPipe()
        let outputPipe = NSPipe()
        
        // TODO: Use Secutiry framework for signing
        
        let signTask = NSTask()
        
        signTask.launchPath = "/usr/bin/openssl"
        signTask.arguments = ["dgst", "-sha256", "-binary", "-passin", "pass:\(passphrase)", "-sign", privateKeyURL.path!]
        signTask.standardInput = inputPipe
        signTask.standardOutput = outputPipe
        
        inputPipe.fileHandleForWriting.writeData(manifestData)
        inputPipe.fileHandleForWriting.closeFile()
        
        signTask.launch()
        signTask.waitUntilExit()
        
        let signedManifestData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        
        let base64ManifestString = manifestData.base64EncodedStringWithOptions([])
        let base64SignedManifestString = signedManifestData.base64EncodedStringWithOptions([])
        
        return "\(base64ManifestString):\(base64SignedManifestString)"
    }
    
}
