//
//  CHJSHttp.h
//  Chanify
//
//  Created by WizJin on 2022/4/24.
//

#import <JavaScriptCore/JavaScriptCore.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CHJSIHttpBuffer <JSExport>

- (NSString *)toString;

@end

@protocol CHJSIHttpClientTask <JSExport>

@property (nonatomic, readonly, assign) NSInteger statusCode;
@property (nonatomic, readonly, nullable, strong) NSDictionary *headers;

JSExportAs(on, - (id<CHJSIHttpClientTask>)on:(NSString *)event callback:(JSValue *)callback);
JSExportAs(setEncoding, - (void)setEncoding:(NSString *)code);
- (void)resume;

@end

@protocol CHJSIHttpClientRequest <JSExport>

JSExportAs(on, - (id<CHJSIHttpClientRequest>)on:(NSString *)event callback:(JSValue *)callback);
JSExportAs(write, - (void)write:(NSString *)data);
- (void)end;

@end

@protocol CHJSIHttp <JSExport>

JSExportAs(get, - (id<CHJSIHttpClientRequest>)get:(id)u);
JSExportAs(request, - (id<CHJSIHttpClientRequest>)request:(id)u);

@end

@interface CHJSHttp : NSObject<CHJSIHttp>

+ (instancetype)moduleWithTLS:(BOOL)tls;


@end

NS_ASSUME_NONNULL_END
