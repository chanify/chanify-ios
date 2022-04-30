//
//  CHScriptManager.m
//  Chanify
//
//  Created by WizJin on 2022/4/1.
//

#import "CHScriptManager.h"
#import "CHUserDataSource.h"
#import "CHJSConsole.h"
#import "CHJSChanify.h"
#import "CHJSBuffer.h"
#import "CHJSHttp.h"
#import "CHRouter.h"
#import "CHTheme.h"

@interface CHScriptContext : NSObject

@property (nonatomic, readonly, weak) CHUserDataSource *ds;
@property (nonatomic, readonly, strong) NSMutableDictionary<NSString *, id> *modules;
@property (nonatomic, readonly, strong) JSContext *context;
@property (nonatomic, readonly, strong) NSURL *url;

@end

@implementation CHScriptContext

- (instancetype)initWithDatasource:(CHUserDataSource *)ds url:(NSURL *)url {
    if (self = [super init]) {
        _ds = ds;
        _url = url;
        _modules = [NSMutableDictionary new];
        _context = [JSContext new];
        [self loadModulesToContext:self.context];
    }
    return self;
}

- (BOOL)run:(NSString *)script {
    [self.context evaluateScript:script withSourceURL:self.url];
    if (self.context.exception != nil) {
        [CHRouter.shared makeToast:self.context.exception.description color:CHTheme.shared.alertColor];
    }
    return YES;
}

#pragma mark - Private Methods
- (nullable id)loadModule:(NSString *)name {
    id res = [self.modules valueForKey:name];
    if (res == nil) {
        if ([name isEqualToString:@"chanify"]) {
            res = [CHJSChanify moduleWithURL:self.url];
        } else if ([name isEqualToString:@"http"]) {
            res = [CHJSHttp moduleWithTLS:NO];
        } else if ([name isEqualToString:@"https"]) {
            res = [CHJSHttp moduleWithTLS:YES];
        } else {
            NSString *script = [self.ds scriptContentWithName:name type:@"module"];
            if (script.length > 0) {
                JSContext *context = [[JSContext alloc] initWithVirtualMachine:self.context.virtualMachine];
                context[@"module"] = @{};
                context[@"exports"] = @{};
                [self loadModulesToContext:context];
                JSValue *ret = [context evaluateScript:[script stringByAppendingString:@";module.exports??exports"]];
                if (context.exception != nil) {
                    NSString *msg = [NSString stringWithFormat:@"%@.js | %@", name, context.exception.description];
                    self.context.exception = [JSValue valueWithNewErrorFromMessage:msg inContext:self.context];
                } else if (ret != nil) {
                    res = [JSManagedValue managedValueWithValue:ret];
                }
            }
        }
        if (res != nil) {
            [self.modules setValue:res forKey:name];
        }
    }
    return res;
}

- (void)loadModulesToContext:(JSContext *)context {
    @weakify(self);
    context[@"Buffer"] = CHJSBuffer.shared;
    context[@"console"] = CHJSConsole.shared;
    context[@"sleep"] = ^(int ms) { usleep(ms*1000); };
    context[@"require"] = ^id (NSString *name) {
        @strongify(self);
        return [self loadModule:name];
    };
}

@end

@interface CHScriptManager ()

@property (nonatomic, readonly, weak) CHUserDataSource *ds;

@end

@implementation CHScriptManager

+ (instancetype)scriptManagerWithUID:(NSString *)uid datasource:(CHUserDataSource *)ds {
    return [[self.class alloc] initWithUID:uid datasource:ds];
}

- (instancetype)initWithUID:(NSString *)uid datasource:(CHUserDataSource *)ds {
    if (self = [super init]) {
        _uid = uid;
        _ds = ds;
    }
    return self;
}

- (void)close {
}

- (BOOL)runScript:(NSString *)name type:(NSString *)type url:(NSURL *)url {
    BOOL res = YES;
    NSString *script = [self.ds scriptContentWithName:name type:type];
    if (script.length <= 0) {
        res = NO;
    } else {
        CHScriptContext *context = [[CHScriptContext alloc] initWithDatasource:self.ds url:url];
        res = [context run:script];
    }
    return res;
}


@end
