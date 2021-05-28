//
//  CHDataItemCell.h
//  iOS
//
//  Created by WizJin on 2021/5/26.
//

#import "CHTableViewCell.h"
#import "CHWebCacheManager.h"

NS_ASSUME_NONNULL_BEGIN

#define kCHDataItemCellMargin   16.0

@interface CHDataItemCell : CHTableViewCell

@property (nonatomic, nullable, strong) NSURL *url;

+ (CGFloat)cellHeight;
- (void)setURL:(NSURL *)url manager:(CHWebCacheManager *)manager;


@end

NS_ASSUME_NONNULL_END
