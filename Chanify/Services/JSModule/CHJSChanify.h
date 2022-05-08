//
//  CHJSChanify.h
//  Chanify
//
//  Created by WizJin on 2022/4/24.
//

#import <JavaScriptCore/JavaScriptCore.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CHJSIMessage <JSExport>

@property (nonatomic, readonly, strong) NSDate *timestamp;
@property (nonatomic, readonly, assign) NSInteger type;
@property (nonatomic, readonly, nullable, strong) NSString *title;
@property (nonatomic, readonly, nullable, strong) NSString *text;
@property (nonatomic, readonly, nullable, strong) NSString *link;
@property (nonatomic, readonly, nullable, strong) NSString *sound;
@property (nonatomic, readonly, nullable, strong) NSString *copytext;

JSExportAs(readFile, - (void)readFile:(JSValue *)callback);

@end

@protocol CHJSIChanify <JSExport>

@property (nonatomic, readonly, strong) NSDictionary *args;
@property (nonatomic, readonly, strong) NSDictionary *messageType;
@property (nonatomic, nullable, strong) NSString *pasteboard;


JSExportAs(alert, - (void)alert:(id)msg);
JSExportAs(routeTo, - (BOOL)routeTo:(NSString *)url);
JSExportAs(loadMessage, - (nullable id<CHJSIMessage>)loadMessage:(NSString *)mid);

@end

@interface CHJSChanify : NSObject<CHJSIChanify>

@property (nonatomic, readonly, strong) NSDictionary *args;

+ (instancetype)moduleWithURL:(NSURL *)url;


@end

NS_ASSUME_NONNULL_END
