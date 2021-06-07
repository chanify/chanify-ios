//
//  CHCellConfiguration.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHUI.h"
#import "CHMessageModel.h"

NS_ASSUME_NONNULL_BEGIN

@class CHMessagesDataSource;

@interface CHCellConfiguration : NSObject<CHContentConfiguration>

@property (nonatomic, readonly, strong) NSString *mid;

+ (instancetype)cellConfiguration:(CHMessageModel *)model;
+ (NSDictionary<NSString *, CHCollectionViewCellRegistration *> *)cellRegistrations;
- (instancetype)initWithMID:(NSString *)mid;
- (nullable NSString *)mediaThumbnailURL;
- (NSDate *)date;
- (void)setNeedRecalcLayout;
- (CGSize)calcSize:(CGSize)size;


@end

NS_ASSUME_NONNULL_END
