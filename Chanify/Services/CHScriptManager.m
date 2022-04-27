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

- (BOOL)runScript:(NSString *)name url:(NSURL *)url {
    BOOL res = YES;
    NSString *script = [self.ds scriptContentWithName:name];
    if (script.length <= 0) {
        res = NO;
    } else {
        JSContext *context = [JSContext new];
        context[@"Buffer"] = CHJSBuffer.shared;
        context[@"console"] = CHJSConsole.shared;
        context[@"sleep"] = ^(int ms) {
            usleep(ms*1000);
        };
        context[@"require"] = ^id (NSString *name) {
            return loadModule(name, url);
        };
        [context evaluateScript:script withSourceURL:url];
        if (context.exception != nil) {
            [CHRouter.shared makeToast:context.exception.description];
        }
    }
    return res;
}

static inline id loadModule(NSString *name, NSURL *url) {
    if ([name isEqualToString:@"chanify"]) {
        return [CHJSChanify moduleWithURL:url];
    } else if ([name isEqualToString:@"http"]) {
        return [CHJSHttp moduleWithTLS:NO];
    } else if ([name isEqualToString:@"https"]) {
        return [CHJSHttp moduleWithTLS:YES];
    }
    return nil;
}


@end
