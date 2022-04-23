//
//  CHScriptManager.m
//  Chanify
//
//  Created by WizJin on 2022/4/1.
//

#import "CHScriptManager.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import "CHUserDataSource.h"
#import "CHRouter.h"

@protocol CHJSIChanify <JSExport>
@property (nonatomic, readonly, strong) NSDictionary *args;
JSExportAs(routeTo, - (BOOL)routeTo:(NSString *)url);
@end

@interface CHJSChanify : NSObject<CHJSIChanify>

@property (nonatomic, readonly, strong) NSDictionary *args;

- (instancetype)initWithURL:(NSURL *)url;

@end

@implementation CHJSChanify

- (instancetype)initWithURL:(NSURL *)url {
    if (self = [super init]) {
        NSMutableDictionary *args = [NSMutableDictionary new];
        for (NSString *arg in [url.query componentsSeparatedByString:@"&"]) {
            NSArray *items = [arg componentsSeparatedByString:@"="];
            if (items.count > 0) {
                NSString *key = [items.firstObject stringByRemovingPercentEncoding];
                if (key.length > 0) {
                    [args setObject:(items.count > 1 ? [[items objectAtIndex:1] stringByRemovingPercentEncoding] : @"") forKey:key];
                }
            }
        }
        _args = args;
    }
    return self;
}

- (BOOL)routeTo:(NSString *)url {
    return [CHRouter.shared routeTo:url];
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

- (BOOL)runScript:(NSString *)name url:(NSURL *)url {
    BOOL res = NO;
    NSString *script = [self.ds scriptContentWithName:name];
    if (script.length > 0) {
        JSContext *context = [JSContext new];
        context[@"require"] = ^id (NSString *name) {
            if ([name isEqualToString:@"chanify"]) {
                return [[CHJSChanify alloc] initWithURL:url];
            }
            return nil;
        };
        context[@"console"] = @{
            @"log": ^ {
                outputLog(JSContext.currentArguments);
            },
            @"assert": ^(BOOL flag) {
                if (!flag) {
                    NSArray *args = JSContext.currentArguments;
                    if (args.count > 1) {
                        outputLog([args subarrayWithRange:NSMakeRange(1, args.count - 1)]);
                    }
                }
            }
        };
        [context evaluateScript:script withSourceURL:url];
        if (context.exception != nil) {
            [CHRouter.shared makeToast:context.exception.description];
        }
        res = YES;
    }
    return res;
}

static inline void outputLog(NSArray<JSValue *> *args) {
    NSMutableArray<NSString *> *logs = [NSMutableArray arrayWithCapacity:args.count];
    for (JSValue *value in args) {
        [logs addObject:[(value.toObject ?: @"undefined") description]];
    }
    [CHRouter.shared makeToast:[logs componentsJoinedByString:@" "]];
}


@end
