//
//  CHChannelModel.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHChannelModel : NSObject

@property (nonatomic, readonly, strong) NSString *cid;
@property (nonatomic, readonly, strong) NSString *name;
@property (nonatomic, readonly, strong) NSString *icon;
@property (nonatomic, assign) BOOL mute;
@property (nonatomic, assign) uint64_t mid;

+ (instancetype)modelWithCID:(nullable NSString *)cid name:(NSString *)name icon:(NSString *)icon;
- (NSComparisonResult)messageCompare:(CHChannelModel *)rhs;


@end

NS_ASSUME_NONNULL_END
