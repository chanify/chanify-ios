//
//  CHUserModel.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHSecKey.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHUserModel : NSObject

@property (nonatomic, readonly, strong) NSString *uid;
@property (nonatomic, readonly, strong) CHSecKey *key;

+ (nullable instancetype)modelWithKey:(nullable CHSecKey *)key;


@end

NS_ASSUME_NONNULL_END
