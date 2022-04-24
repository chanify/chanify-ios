//
//  CHJSChanify.h
//  Chanify
//
//  Created by WizJin on 2022/4/24.
//

#import <JavaScriptCore/JavaScriptCore.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CHJSIChanify <JSExport>

@property (nonatomic, readonly, strong) NSDictionary *args;

JSExportAs(routeTo, - (BOOL)routeTo:(NSString *)url);

@end

@interface CHJSChanify : NSObject<CHJSIChanify>

@property (nonatomic, readonly, strong) NSDictionary *args;

+ (instancetype)moduleWithURL:(NSURL *)url;


@end

NS_ASSUME_NONNULL_END
