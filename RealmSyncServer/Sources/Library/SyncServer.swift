//
//  SyncServer.swift
//  RealmSyncServer
//
//  Created by Dmitry Obukhov on 5/25/16.
//  Copyright © 2016 Realm Inc. All rights reserved.
//

import Foundation
import Cocoa

enum ServerLogLevel: Int {
    case Nothing
    case Normal
    case Everything
}

protocol SyncServerDelegate: class {
    
    func serverDidStop(server: SyncServer)
    func serverDidOutputLog(server: SyncServer, message: String)
    
}

class SyncServer {
    
    weak var delegate: SyncServerDelegate?
    
    var host: String!
    var port: Int!
    var realmDirectoryPath: String!
    var publicKeyPath: String?
    var logLevel: ServerLogLevel = .Everything
    
    var running: Bool {
        return serverTask?.running ?? false
    }
    
    private var serverTask: NSTask?
    
    func start() {
        guard !running else {
            return
        }
        
        let outputPipe = NSPipe()
        let errorPipe = NSPipe()
        
        let task = NSTask()
        
        task.launchPath = serverTaskLaunchPath()
        task.environment = serverTaskEnvironment()
        task.arguments = serverTaskArguments()
        task.standardOutput = outputPipe
        task.standardError = errorPipe
        
        if !NSFileManager.defaultManager().fileExistsAtPath(realmDirectoryPath) {
            do {
                try NSFileManager.defaultManager().createDirectoryAtPath(realmDirectoryPath, withIntermediateDirectories: true, attributes: nil)
            } catch let error as NSError {
                let alert = NSAlert(error: error)
                alert.informativeText = realmDirectoryPath
                alert.runModal()
            }
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(taskDidTerminate), name: NSTaskDidTerminateNotification, object: task)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(fileHandleDataAvailable), name: NSFileHandleDataAvailableNotification, object: outputPipe.fileHandleForReading)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(fileHandleDataAvailable), name: NSFileHandleDataAvailableNotification, object: errorPipe.fileHandleForReading)
        
        outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        errorPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        
        task.launch()
        
        serverTask = task
    }
    
    func stop() {
        guard running else {
            return
        }
        
        serverTask?.terminate()
        serverTask = nil
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
        
        delegate?.serverDidOutputLog(self, message: "Server terminated.\n")
    }
    
    private func serverTaskLaunchPath() -> String {
        let path = NSBundle.mainBundle().pathForResource("realm-server-dbg-noinst", ofType: nil)!
        
        return path
    }
    
    private func serverTaskEnvironment() -> [String: String]? {
        return ["DYLD_LIBRARY_PATH": NSBundle.mainBundle().resourcePath!]
    }
    
    private func serverTaskArguments() -> [String] {
        var arguments: [String] = []
        
        arguments.append(realmDirectoryPath)
        arguments.append(host)
        
        arguments.append("-p")
        arguments.append(String(port))
        
        if let path = publicKeyPath where path.characters.count > 0 {
            arguments.append("-k")
            arguments.append(path)
        }
        
        arguments.append("-l")
        arguments.append(String(logLevel.rawValue))
        
        return arguments
    }
    
    private dynamic func taskDidTerminate(notification: NSNotification) {
        if let data = (serverTask?.standardError as? NSPipe)?.fileHandleForReading.readDataToEndOfFile() {
            if let message = NSString(data: data, encoding: NSUTF8StringEncoding) as? String where data.length > 0 {
                delegate?.serverDidOutputLog(self, message: message)
            }
        }
        
        stop()
        
        delegate?.serverDidStop(self)
    }
    
    private dynamic func fileHandleDataAvailable(notification: NSNotification) {
        guard let fileHandle = notification.object as? NSFileHandle else {
            return
        }
        
        let data = fileHandle.availableData
        
        if let message = NSString(data: data, encoding: NSUTF8StringEncoding) as? String where data.length > 0 {
            delegate?.serverDidOutputLog(self, message: message)
        }
        
        fileHandle.waitForDataInBackgroundAndNotify()
    }
    
}
