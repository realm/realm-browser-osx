//
//  CredentialsManifest.swift
//  RealmSyncServer
//
//  Created by Dmitry Obukhov on 03/06/16.
//  Copyright © 2016 Realm Inc. All rights reserved.
//

import Foundation

struct CredentialsManifest {
    
    var identity: String
    var appID: String
    var access: CredentialsAccessRights
    
    var valid: Bool {
        return identity.characters.count > 0
    }
    
}

extension CredentialsManifest: JSONRepresentable {

    var JSONRepresentation: AnyObject {
        var json: [String: AnyObject] = [:]

        json["identity"] = identity
        json["app_id"] = appID
        json["access"] = access.JSONRepresentation

        return json
    }

}

extension CredentialsAccessRights: JSONRepresentable {

    var JSONRepresentation: AnyObject {
        var json: [String] = []

        if contains(.Upload) {
            json.append("upload")
        }

        if contains(.Download) {
            json.append("download")
        }

        return json
    }

}