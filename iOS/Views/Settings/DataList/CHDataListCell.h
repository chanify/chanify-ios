//
//  CHDataListCell.h
//  iOS
//
//  Created by WizJin on 2021/5/26.
//

#import "CHTableViewCell.h"
#import "CHFileCacheManager.h"

NS_ASSUME_NONNULL_BEGIN

#define kCHDataListLeftMargin   16.0

@interface CHDataListCell : CHTableViewCell

@property (nonatomic, nullable, strong) NSURL *url;

+ (CGFloat)cellHeight;
- (void)setURL:(NSURL *)url manager:(CHFileCacheManager *)manager;


@end

NS_ASSUME_NONNULL_END
