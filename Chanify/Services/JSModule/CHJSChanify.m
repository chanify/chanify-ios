//
//  CHJSChanify.m
//  Chanify
//
//  Created by WizJin on 2022/4/24.
//

#import "CHJSChanify.h"
#import "CHPasteboard.h"
#import "CHWebFileManager.h"
#import "CHUserDataSource.h"
#import "CHMessageModel.h"
#import "CHJSHttp.h"
#import "CHRouter.h"
#import "CHLogic.h"

@interface CHJSMessage : NSObject<CHJSIMessage>

@property (nonatomic, readonly, strong) CHMessageModel *model;

@end

@implementation CHJSMessage

- (instancetype)initWithModel:(CHMessageModel *)model {
    if (self = [super init]) {
        _model = model;
    }
    return self;
}

- (NSInteger)type {
    return self.model.type;
}

- (NSDate *)timestamp {
    return [NSDate dateFromMID:self.model.mid];
}

- (nullable NSString *)title {
    return self.model.title;
}

- (nullable NSString *)text {
    return self.model.text;
}

- (nullable NSString *)link {
    return self.model.link.absoluteString;
}

- (nullable NSString *)sound {
    return self.model.sound;
}

- (nullable NSString *)copytext {
    return self.model.copytext;
}

+ (NSInteger)TEXT {
    return CHMessageTypeText;
}

+ (NSInteger)IMAGE {
    return CHMessageTypeImage;
}

+ (NSInteger)VIDEO {
    return CHMessageTypeVideo;
}

+ (NSInteger)AUDIO {
    return CHMessageTypeAudio;
}

+ (NSInteger)LINK {
    return CHMessageTypeLink;
}

+ (NSInteger)FILE {
    return CHMessageTypeFile;
}

+ (NSInteger)ACTION {
    return CHMessageTypeAction;
}

- (void)readFile:(JSValue *)callback {
    if (callback != nil && !callback.isNull) {
        if (self.model.type != CHMessageTypeFile) {
            [callback callWithArguments:@[
                [JSValue valueWithNewErrorFromMessage:@"Not file type" inContext:callback.context],
                [JSValue valueWithNullInContext:callback.context]]];
        } else {
            NSURL *url = [CHLogic.shared.webFileManager loadLocalFileURL:self.model.fileURL filename:self.model.filename];
            if (url == nil) {
                [callback callWithArguments:@[
                    [JSValue valueWithNewErrorFromMessage:@"Invalid file path" inContext:callback.context],
                    [JSValue valueWithNullInContext:callback.context]]];
            } else {
                NSData *data = [NSData dataFromNoCacheURL:url];
                [callback callWithArguments:@[
                    [JSValue valueWithNullInContext:callback.context],
                    [[CHJSHttpBuffer alloc] initWithData:data]]];
            }
        }
    }
}

@end

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

- (nullable id<CHJSIMessage>)loadMessage:(NSString *)mid {
    CHJSMessage *message = nil;
    CHMessageModel *model = [CHLogic.shared.userDataSource messageWithMID:mid];
    if (model != nil) {
        message = [[CHJSMessage alloc] initWithModel:model];
    }
    return message;
}


@end
