//
//  CHJSChanify.m
//  Chanify
//
//  Created by WizJin on 2022/4/24.
//

#import "CHJSChanify.h"
#import "CHPasteboard.h"
#import "CHRouter.h"

@implementation CHJSChanify

+ (instancetype)moduleWithURL:(NSURL *)url {
    return [[self.class alloc] initWithURL:url];
}

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

- (NSString *)pasteboard {
    return CHPasteboard.shared.stringValue;
}

- (void)setPasteboard:(NSString *)pasteboard {
    CHPasteboard.shared.stringValue = pasteboard;
}

- (void)alert:(id)msg {
    if (msg != nil) {
        NSString *title = nil;
        NSString *message = nil;
        NSString *action = nil;
        JSValue *callback = nil;
        if ([msg isKindOfClass:NSString.class]) {
            message = (NSString *)msg;
        } else if ([msg isKindOfClass:NSDictionary.class]) {
            NSDictionary *options = (NSDictionary *)msg;
            title = [options valueForKey:@"title"];
            message = [options valueForKey:@"message"];
            action = [options valueForKey:@"action"];
        } else {
            message = [msg description];
        }
        if (JSContext.currentArguments.count > 1) {
            callback = [JSContext.currentArguments objectAtIndex:1];
        }
        if (message.length > 0) {
            [CHRouter.shared showAlertWithTitle:title message:message action:action handler:^{
                if (callback != nil && !callback.isNull) {
                    [callback callWithArguments:@[]];
                }
            }];
        }
    }
}

- (BOOL)routeTo:(NSString *)url {
    return [CHRouter.shared routeTo:url];
}


@end
