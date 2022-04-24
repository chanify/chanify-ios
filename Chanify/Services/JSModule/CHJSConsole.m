//
//  CHJSConsole.m
//  Chanify
//
//  Created by WizJin on 2022/4/24.
//

#import "CHJSConsole.h"
#import "CHRouter.h"

@implementation CHJSConsole

+ (instancetype)shared {
    static CHJSConsole *console = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        console = [CHJSConsole new];
    });
    return console;
}

#pragma mark - JS Methods
- (void)doLog:(id)msg {
    outputLog(JSContext.currentArguments);
}

- (void)doInfo:(id)msg {
    outputLog(JSContext.currentArguments);
}

- (void)doWarn:(id)msg {
    outputLog(JSContext.currentArguments);
}

- (void)doDebug:(id)msg {
    outputLog(JSContext.currentArguments);
}

- (void)doError:(id)msg {
    outputLog(JSContext.currentArguments);
}

- (void)doAssert:(BOOL)flag {
    if (!flag) {
        NSArray *args = JSContext.currentArguments;
        if (args.count > 1) {
            outputLog([args subarrayWithRange:NSMakeRange(1, args.count - 1)]);
        }
    }
    outputLog(JSContext.currentArguments);
}

#pragma mark - Private Methods
static inline void outputLog(NSArray<JSValue *> *args) {
    if (args.count > 0) {
        NSString *msg = [args.firstObject.toObject description];
        if (args.count > 1) {
            NSInteger index = 1;
            NSMutableString *str = [NSMutableString new];
            for (NSInteger i = 0; i < msg.length; i++) {
                unichar c = [msg characterAtIndex:i];
                if(c == '%') {
                    if (++i < msg.length) {
                        switch([msg characterAtIndex:i]) {
                            default: continue;
                            case '%': break;
                            case 'd':
                            case 'i':
                            case 'f':
                            case 's':
                            case 'j':
                            case 'o':
                            case 'O':
                                if (index >= args.count) {
                                    [str appendFormat:@"%%%c", [msg characterAtIndex:i]];
                                    i = msg.length;
                                } else {
                                    JSValue *value = [args objectAtIndex:index++];
                                    [str appendString:[value.toObject description]];
                                }
                                continue;
                        }
                    }
                }
                [str appendFormat:@"%c", c];
            }
            while (index < args.count) {
                JSValue *value = [args objectAtIndex:index++];
                [str appendFormat:@" %@", [value.toObject description]];
            }
            msg = str;
        }
        [CHRouter.shared makeToast:msg];
    }
}


@end
