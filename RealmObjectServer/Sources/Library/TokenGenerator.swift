//
//  TokenGenerator.swift
//  RealmSyncServer
//
//  Created by Dmitry Obukhov on 01/06/16.
//  Copyright © 2016 Realm Inc. All rights reserved.
//

import Foundation
import Security

class TokenGenerator {
    
    private var privateKey: SecKey!
    
    init?(privateKeyURL: NSURL) {
        guard let key = loadPrivateKeyAtURL(privateKeyURL) else {
            return nil
        }
        
        privateKey = key
    }
    
    func generateTokenForJSONObject(object: JSONRepresentable) throws -> String {
        let manifestData = try NSJSONSerialization.dataWithJSONObject(object.JSONRepresentation, options: .PrettyPrinted)
        
        var error: Unmanaged<CFErrorRef>?
        
        guard let signTransform = SecSignTransformCreate(privateKey, &error) else {
            throw error!.takeRetainedValue()
        }
    
        guard SecTransformSetAttribute(signTransform, kSecDigestTypeAttribute, kSecDigestSHA2, &error) else {
            throw error!.takeRetainedValue()
        }
        
        guard SecTransformSetAttribute(signTransform, kSecDigestLengthAttribute, 256, &error) else {
            throw error!.takeRetainedValue()
        }
        
        guard SecTransformSetAttribute(signTransform, kSecTransformInputAttributeName, manifestData, &error) else {
            throw error!.takeRetainedValue()
        }
        
        guard let signedManifestData = SecTransformExecute(signTransform, &error) as? NSData else {
            throw error!.takeRetainedValue()
        }

        let base64ManifestString = manifestData.base64EncodedStringWithOptions([])
        let base64SignedManifestString = signedManifestData.base64EncodedStringWithOptions([])
        
        return "\(base64ManifestString):\(base64SignedManifestString)"
    }
    
    private func loadPrivateKeyAtURL(url: NSURL) -> SecKeyRef? {
        guard let keyData = NSData(contentsOfURL: url) else {
            return nil
        }
        
        var inputFormat: SecExternalFormat = .FormatPEMSequence
        var itemType: SecExternalItemType = .ItemTypePrivateKey
        
        let flags: SecItemImportExportFlags = SecItemImportExportFlags(rawValue: 0)
        
        var keyParams = SecItemImportExportKeyParameters(
            version: 0,
            flags: SecKeyImportExportFlags(rawValue: 0),
            passphrase: Unmanaged.passUnretained(""),
            alertTitle: Unmanaged.passUnretained(""),
            alertPrompt: Unmanaged.passUnretained(""),
            accessRef: nil,
            keyUsage: nil,
            keyAttributes: nil
        )
        
        var importArray: CFArray? = nil
        
        guard SecItemImport(keyData, nil, &inputFormat, &itemType, flags, &keyParams, nil, &importArray) == 0 else {
            return nil
        }
        
        let items = importArray! as NSArray
        
        guard items.count > 0 else {
            return nil
        }
        
        return (items[0] as! SecKey)
    }
    
}
