//
//  CHBlockedModel.h
//  Chanify
//
//  Created by WizJin on 2021/6/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHBlockedModel : NSObject

@property (nonatomic, readonly, strong) NSString *raw;
@property (nonatomic, nullable, readonly, strong) NSDate *expired;
@property (nonatomic, nullable, readonly, strong) NSData *channel;
@property (nonatomic, nullable, readonly, strong) NSString *nid;

+ (instancetype)modelWithRaw:(NSString *)raw;


@end

NS_ASSUME_NONNULL_END
