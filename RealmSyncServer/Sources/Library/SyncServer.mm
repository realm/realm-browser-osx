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
        [_delegate loggerDidOutputMessage:[NSString stringWithUTF8String:string.c_str()]];
    }
    
private:
    __weak id<SyncServerLoggerDelegate> _delegate;
};

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

- (BOOL)start:(NSError *__autoreleasing  _Nullable *)error {
    bool log_everything = self.logLevel == SyncServerLogLevelEverything;
    
    util::Optional<sync::PKey> pkey;
    if (self.publicKeyURL != nil) {
        try {
            pkey = sync::PKey::load_public(std::string(self.publicKeyURL.path.UTF8String));
        } catch (const realm::sync::CryptoError& e) {
            if (error != nil) {
                *error = [self errorWithErrorCode:-1 description:@"Error while loading public key file" stdException:e];
            }
            
            return NO;
        }
    }
    
    try {
        _server.reset(new sync::Server(std::string(self.rootDirectoryURL.path.UTF8String), std::move(pkey), _logger.get(), log_everything));
    } catch (const realm::util::File::AccessError& e) {
        if (error != nil) {
            *error = [self errorWithErrorCode:-2 description:@"Error while opening root directory" stdException:e];
        }
        
        return NO;
    }

    try {
        _server->start(std::string(self.host.UTF8String), std::string([NSString stringWithFormat:@"%ld", (long)self.port].UTF8String), false);
    } catch (std::exception& e) {
        if (error != nil) {
            *error = [self errorWithErrorCode:-3 description:@"Error starting the server" stdException:e];
        }
        
        return NO;
    }

    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __typeof(self) strongSelf = weakSelf;
        
        strongSelf->_server->run();
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            strongSelf.running = NO;
            
            [strongSelf.delegate syncServer:strongSelf didOutputLogMessage:@"Server terminated"];
            [strongSelf.delegate syncServerDidStop:strongSelf];
        });
    });
    
    self.running = YES;
    
    return YES;
}

- (void)stop {
    if (_server != NULL) {
        _server->stop();
        _server.reset();
    }
}

- (NSError *)errorWithErrorCode:(NSInteger)code description:(NSString *)description stdException:(const std::exception &)e {
    NSDictionary *userInfo = @{
        NSLocalizedDescriptionKey: description,
        NSLocalizedRecoverySuggestionErrorKey: [NSString stringWithUTF8String:e.what()],
    };
    
    return [[NSError alloc] initWithDomain:SyncServerErrorDomain code:code userInfo:userInfo];
}

#pragma mark - RLMSyncServerWrapperLoggerDelegate

- (void)loggerDidOutputMessage:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate syncServer:self didOutputLogMessage:message];
    });
}

@end
