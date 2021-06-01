//
//  CHRouter+OSX.h
//  OSX
//
//  Created by WizJin on 2021/5/31.
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHRouter : NSObject

@property (nonatomic, readonly, strong) NSWindow *window;

+ (instancetype)shared;
- (void)launch;
- (void)close;
- (void)handleReopen:(id)sender;
- (BOOL)routeTo:(NSString *)url;
- (BOOL)routeTo:(NSString *)url withParams:(nullable NSDictionary<NSString *, id> *)params;


@end

NS_ASSUME_NONNULL_END
