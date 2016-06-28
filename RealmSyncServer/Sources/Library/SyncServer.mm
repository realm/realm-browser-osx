//
//  SyncServer.mm
//  RealmSyncServer
//
//  Created by Dmitry Obukhov on 21/06/16.
//  Copyright © 2016 Realm Inc. All rights reserved.
//

#import "SyncServer.h"
#import <realm/sync/server.hpp>

NSString * const SyncServerErrorDomain = @"io.realm.syncserver";

using namespace realm;

@protocol SyncServerLoggerDelegate

- (void)loggerDidOutputMessage:(NSString *)message;

@end

class SyncServerLogger: public util::Logger {
public:
    explicit SyncServerLogger(id<SyncServerLoggerDelegate> delegate) noexcept : _delegate(delegate) { }
    
protected:
    void do_log(std::string string) override {
        [_delegate loggerDidOutputMessage:@(string.c_str())];
    }
    
private:
    __weak id<SyncServerLoggerDelegate> _delegate;
};

static NSError *errorWithErrorCode(SyncServerError errorCode, NSString *description, const std::exception &e) {
    NSDictionary *userInfo = @{
        NSLocalizedDescriptionKey: description,
        NSLocalizedRecoverySuggestionErrorKey: @(e.what()),
    };
    
    return [[NSError alloc] initWithDomain:SyncServerErrorDomain code:errorCode userInfo:userInfo];
}

@interface SyncServer() <SyncServerLoggerDelegate>

@property (nonatomic, assign) BOOL running;

@end

@implementation SyncServer {
    std::unique_ptr<sync::Server> _server;
    std::unique_ptr<util::Logger> _logger;
}

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _logger.reset(new SyncServerLogger(self));
    }
    
    return self;
}

- (void)dealloc {
    [self stop];
}

- (BOOL)start:(NSError *__autoreleasing *)error {
    bool log_everything = self.logLevel == SyncServerLogLevelEverything;
    
    NSError *__autoreleasing localError;
    if (error == NULL) {
        error = &localError;
    }
    
    util::Optional<sync::PKey> pkey;
    if (self.publicKeyURL != nil) {
        try {
            pkey = sync::PKey::load_public(self.publicKeyURL.path.UTF8String);
        } catch (const realm::sync::CryptoError& e) {
            *error = errorWithErrorCode(SyncServerErrorLoadingPublicKey, @"Error while loading public key file", e);
            return NO;
        }
    }
    
    try {
        _server.reset(new sync::Server(self.rootDirectoryURL.path.UTF8String, std::move(pkey), _logger.get(), log_everything));
    } catch (const realm::util::File::AccessError& e) {
        *error = errorWithErrorCode(SyncServerErrorOpenningRootDirectory, @"Error while opening root directory", e);
        return NO;
    }

    try {
        _server->start(self.host.UTF8String, [NSString stringWithFormat:@"%ld", (long)self.port].UTF8String);
    } catch (std::exception& e) {
        *error = errorWithErrorCode(SyncServerErrorStartingServer, @"Error starting the server", e);
        return NO;
    }

    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __typeof(self) strongSelf = weakSelf;
        
        try {
            strongSelf->_server->run();
        } catch (std::exception& e) {
            // The only thing we can do here is to output error as a log message
            dispatch_async(dispatch_get_main_queue(), ^{
                [strongSelf.delegate syncServer:strongSelf didOutputLogMessage:@(e.what())];
            });
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            strongSelf.running = NO;
            
            [strongSelf.delegate syncServer:strongSelf didOutputLogMessage:@"Server terminated"];
            [strongSelf.delegate syncServerDidStop:strongSelf];
        });
    });
    
    self.running = YES;
    
    return YES;
}

- (void)stop {
    if (_server) {
        _server->stop();
        _server.reset();
    }
}

#pragma mark - SyncServerLoggerDelegate

- (void)loggerDidOutputMessage:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate syncServer:self didOutputLogMessage:message];
    });
}

@end
