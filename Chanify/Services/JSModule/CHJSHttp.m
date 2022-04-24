//
//  CHJSHttp.m
//  Chanify
//
//  Created by WizJin on 2022/4/24.
//

#import "CHJSHttp.h"

@interface CHJSHttpBuffer : NSObject<CHJSIHttpBuffer>

@property (nonatomic, nullable, strong) NSData *data;

@end

@implementation CHJSHttpBuffer

- (instancetype)initWithData:(NSData *)data {
    if(self = [super init]) {
        _data = data ?: [NSData new];
    }
    return self;
}

- (NSString *)toString {
    return [[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding];
}


@end


@interface CHJSHttpClientTask : NSObject<CHJSIHttpClientTask>

@property (nonatomic, readwrite, assign) NSInteger statusCode;
@property (nonatomic, readwrite, nullable, strong) NSDictionary *headers;
@property (nonatomic, nullable, strong) NSString *respEncoding;
@property (nonatomic, nullable, strong) JSManagedValue *dataCallback;
@property (nonatomic, nullable, strong) JSManagedValue *endCallback;
@property (nonatomic, nullable, strong) JSManagedValue *errorCallback;

@end

@interface CHJSHttpSession : NSObject<NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (nonatomic, readonly, strong) NSURLSession *session;

@end

@implementation CHJSHttpSession

+ (instancetype)shared {
    static CHJSHttpSession *session;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        session = [CHJSHttpSession new];
    });
    return session;
}

- (instancetype)init {
    if (self = [super init]) {
        _session = [NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.ephemeralSessionConfiguration delegate:self delegateQueue:nil];
    }
    return self;
}

- (void)startTaskWithRequest:(NSURLRequest *)request clientTask:(CHJSHttpClientTask *)clientTask {
    __block NSData *resData = nil;
    __block NSError *resError = nil;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        resData = data;
        resError = error;
        if ([response isKindOfClass:NSHTTPURLResponse.class]) {
            NSHTTPURLResponse *resp = (NSHTTPURLResponse *)response;
            clientTask.statusCode = resp.statusCode;
            clientTask.headers = resp.allHeaderFields;
        }
        dispatch_semaphore_signal(sem);
    }];
    [task resume];
    dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_WALLTIME_NOW, 10*NSEC_PER_SEC));
    if (resError != nil) {
        if (clientTask.errorCallback != nil) {
            [clientTask.errorCallback.value callWithArguments:@[[resError description]]];
        }
    } else {
        if (clientTask.dataCallback != nil) {
            NSData *rData = resData ?: [NSData new];
            id arg;
            if ([clientTask.respEncoding isEqualToString:@"utf8"]) {
                arg = [[NSString alloc] initWithData:rData encoding:NSUTF8StringEncoding];
            } else {
                arg = [[CHJSHttpBuffer alloc] initWithData:rData];
            }
            [clientTask.dataCallback.value callWithArguments:@[arg]];
        }
        if (clientTask.endCallback != nil) {
            [clientTask.endCallback.value callWithArguments:@[]];
        }
    }
}

#pragma mark - NSURLSessionTaskDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error {

}

@end

@implementation CHJSHttpClientTask

- (id<CHJSIHttpClientTask>)on:(NSString *)event callback:(JSValue *)callback {
    if (callback != nil && !callback.isNull) {
        if ([event isEqualToString:@"data"]) {
            self.dataCallback = [JSManagedValue managedValueWithValue:callback];
        } else if ([event isEqualToString:@"end"]) {
            self.endCallback = [JSManagedValue managedValueWithValue:callback];
        }
    }
    return self;
}

- (void)setEncoding:(NSString *)code {
    self.respEncoding = code;
}

- (void)resume {
}

@end

@interface CHJSHttpClientRequest : NSObject<CHJSIHttpClientRequest>

@property (nonatomic, readonly, assign) BOOL isClosed;
@property (nonatomic, readonly, strong) NSMutableURLRequest *request;
@property (nonatomic, nullable, strong) JSManagedValue *callback;
@property (nonatomic, nullable, strong) CHJSHttpClientTask *task;

@end

@implementation CHJSHttpClientRequest

- (instancetype)initWithRequest:(NSMutableURLRequest *)request callback:(JSManagedValue *)callback {
    if (self = [super init]) {
        _isClosed = NO;
        _request = request;
        _callback = callback;
        _task = [CHJSHttpClientTask new];
    }
    return self;
}

- (void)dealloc {
    [self end];
}

- (id<CHJSIHttpClientRequest>)on:(NSString *)event callback:(JSValue *)callback {
    if (callback != nil && !callback.isNull) {
        if ([event isEqualToString:@"error"]) {
            self.task.errorCallback = [JSManagedValue managedValueWithValue:callback];
        }
    }
    return self;
}

- (void)write:(NSString *)data {
    self.request.HTTPBody = [data dataUsingEncoding:NSUTF8StringEncoding];
}

- (void)end {
    if (!self.isClosed) {
        _isClosed = YES;
        if (self.request != nil) {
            if (self.callback != nil) {
                [self.callback.value callWithArguments:@[self.task]];
            }
            [CHJSHttpSession.shared startTaskWithRequest:self.request clientTask:self.task];
        }
    }
}

@end

@interface CHJSHttp ()

@property (nonatomic, readonly, assign) BOOL isTLS;

@end

@implementation CHJSHttp

+ (instancetype)moduleWithTLS:(BOOL)tls {
    return [[self.class alloc] initWithTLS:tls];
}

- (instancetype)initWithTLS:(BOOL)tls {
    if (self = [super init]) {
        _isTLS = tls;
    }
    return self;
}

- (id<CHJSIHttpClientRequest>)get:(id)u {
    return [self request:u];
}

- (id<CHJSIHttpClientRequest>)request:(id)u {
    NSMutableURLRequest *request;
    NSInteger index = 0;
    NSArray<JSValue *> *args = JSContext.currentArguments;
    if (![u isKindOfClass:NSString.class]) {
        request = [NSMutableURLRequest new];
    } else {
        request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:(NSString *)u]];
        index++;
    }
    if (index < args.count) {
        JSValue *opts = [args objectAtIndex:index];
        if ([opts.toObject isKindOfClass:NSDictionary.class]) {
            index++;
            NSDictionary *options = (NSDictionary *)opts.toObject;
            NSString *hostname = [options valueForKey:@"hostname"];
            if (hostname.length > 0) {
                NSURLComponents *url = [NSURLComponents new];
                url.scheme = (self.isTLS ? @"https" : @"http");
                url.host = hostname;
                NSNumber *port = [options valueForKey:@"port"];
                if (port != nil) {
                    url.port = port;
                }
                NSString *path = [options valueForKey:@"path"];
                if (path.length > 0) {
                    url.path = path;
                }
                request.URL = url.URL;
            }
            NSString *method = [options valueForKey:@"method"];
            if (method.length > 0) {
                request.HTTPMethod = method;
            }
            NSDictionary *headers = (NSDictionary *)[options valueForKey:@"headers"];
            if (headers.count > 0) {
                for (NSString *key in headers) {
                    id value = headers[key];
                    if (value) {
                        [request setValue:[NSString stringWithFormat:@"%@", value] forHTTPHeaderField:key];
                    }
                }
            }
        }
    }
    JSManagedValue *callback = nil;
    if (index < args.count) {
        JSValue *cb = [args objectAtIndex:index];
        if (cb != nil && !cb.isNull) {
            callback = [JSManagedValue managedValueWithValue:cb];
        }
    }
    return [[CHJSHttpClientRequest alloc] initWithRequest:request callback:callback];
}


@end
