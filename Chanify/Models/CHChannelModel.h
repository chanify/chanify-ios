//
//  CHChannelModel.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CHChanType) {
    CHChanTypeSys   = 1,
    CHChanTypeUser  = 2,
};

@interface CHChannelModel : NSObject

@property (nonatomic, readonly, strong) NSString *cid;
@property (nonatomic, readonly, strong) NSString *code;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *icon;
@property (nonatomic, assign) CHChanType type;
@property (nonatomic, assign) BOOL mute;
@property (nonatomic, assign) uint64_t mid;

+ (nullable instancetype)modelWithCID:(nullable NSString *)cid name:(nullable NSString *)name icon:(nullable NSString *)icon;
+ (nullable instancetype)modelWithCode:(NSString *)code name:(nullable NSString *)name icon:(nullable NSString *)icon;
- (NSComparisonResult)messageCompare:(CHChannelModel *)rhs;
- (NSString *)title;


@end

NS_ASSUME_NONNULL_END
