//
//  SyncServer.swift
//  RealmSyncServer
//
//  Created by Dmitry Obukhov on 5/25/16.
//  Copyright © 2016 Realm Inc. All rights reserved.
//

import Foundation
import Cocoa

enum SyncServerLogLevel: Int {
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
    var realmDirectoryURL: NSURL?
    
    var publicKeyURL: NSURL?
    var enableAuthentication = true
    
    var logLevel: SyncServerLogLevel = .Everything
    
    var realmDirectoryPath: String!
    
    var running: Bool {
        return serverTask != nil
    }
    
    private var serverTask: NSTask?
    private let serverTaskExecutableName = "realm-server-dbg-noinst"
    
    deinit {
        stop()
    }
    
    func start() throws {
        guard !running else {
            return
        }
        
        if !NSFileManager.defaultManager().fileExistsAtPath(realmDirectoryPath) {
            try NSFileManager.defaultManager().createDirectoryAtPath(realmDirectoryPath, withIntermediateDirectories: true, attributes: nil)
        }
        
        let outputPipe = NSPipe()
        let errorPipe = NSPipe()
        
        let task = NSTask()
        
        task.launchPath = serverTaskLaunchPath()
        task.arguments = serverTaskArguments()
        task.standardOutput = outputPipe
        task.standardError = errorPipe
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(fileHandleDataAvailable), name: NSFileHandleDataAvailableNotification, object: outputPipe.fileHandleForReading)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(fileHandleDataAvailable), name: NSFileHandleDataAvailableNotification, object: errorPipe.fileHandleForReading)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(taskDidTerminate), name: NSTaskDidTerminateNotification, object: task)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(stop), name: NSApplicationWillTerminateNotification, object: nil)
        
        outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        errorPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        
        task.launch()
        
        serverTask = task
    }
    
    dynamic func stop() {
        guard running else {
            return
        }
        
        serverTask?.terminate()
        serverTask = nil
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
        
        delegate?.serverDidOutputLog(self, message: "Server terminated.\n")
    }
    
    private func serverTaskLaunchPath() -> String {
        return NSBundle.mainBundle().pathForResource(serverTaskExecutableName, ofType: nil)!
    }
    
    private func serverTaskArguments() -> [String] {
        var arguments: [String] = []
        
        arguments.append("-r")
        arguments.append(realmDirectoryPath)
        
        arguments.append("-L")
        arguments.append(host)
        
        arguments.append("-p")
        arguments.append(String(port))
        
        if let path = publicKeyURL?.path where enableAuthentication {
            arguments.append("-k")
            arguments.append(path)
        }
        
        arguments.append("-l")
        arguments.append(String(logLevel.rawValue))
        
        return arguments
    }
    
    private dynamic func taskDidTerminate(notification: NSNotification) {
        if let delegate = delegate, let fileHandle = (serverTask?.standardError as? NSPipe)?.fileHandleForReading {
            let data = fileHandle.readDataToEndOfFile()
            
            if let message = NSString(data: data, encoding: NSUTF8StringEncoding) as? String where data.length > 0 {
                delegate.serverDidOutputLog(self, message: message)
            }
        }
        
        stop()
        
        delegate?.serverDidStop(self)
    }
    
    private dynamic func fileHandleDataAvailable(notification: NSNotification) {
        guard let delegate = delegate, let fileHandle = notification.object as? NSFileHandle else {
            return
        }
        
        let data = fileHandle.availableData
        
        if let message = NSString(data: data, encoding: NSUTF8StringEncoding) as? String where data.length > 0 {
            delegate.serverDidOutputLog(self, message: message)
        }
        
        fileHandle.waitForDataInBackgroundAndNotify()
    }
    
}
