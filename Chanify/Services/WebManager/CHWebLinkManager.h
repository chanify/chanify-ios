//
//  CHWebLinkManager.h
//  Chanify
//
//  Created by WizJin on 2021/4/3.
//

#import "CHWebCacheManager.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CHWebLinkItem <NSObject>

- (void)webLinkUpdated:(nullable NSDictionary *)item;

@end

@interface CHWebLinkManager : CHWebCacheManager

+ (instancetype)webLinkManagerWithURL:(NSURL *)fileBaseDir;
- (void)loadLinkFromURL:(nullable NSURL *)url toItem:(id<CHWebLinkItem>)item;
- (void)close;


@end

NS_ASSUME_NONNULL_END
