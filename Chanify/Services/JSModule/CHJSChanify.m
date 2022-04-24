//
//  CHJSChanify.m
//  Chanify
//
//  Created by WizJin on 2022/4/24.
//

#import "CHJSChanify.h"
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

- (BOOL)routeTo:(NSString *)url {
    return [CHRouter.shared routeTo:url];
}


@end
