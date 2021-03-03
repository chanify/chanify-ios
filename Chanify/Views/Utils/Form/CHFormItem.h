//
//  CHFormItem.h
//  Chanify
//
//  Created by WizJin on 2021/3/3.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHFormItem : NSObject

@property (nonatomic, readonly, strong) UIListContentConfiguration *configuration;
@property (nonatomic, nullable, copy) dispatch_block_t action;

+ (instancetype)itemWithName:(NSString *)name image:(UIImage *)image;
+ (instancetype)itemWithName:(NSString *)name value:(NSString *)value;
+ (instancetype)itemWithName:(NSString *)name value:(NSString *)value action:(nullable dispatch_block_t)action;
+ (instancetype)itemWithName:(NSString *)name code:(NSString *)code action:(nullable dispatch_block_t)action;
+ (instancetype)itemWithName:(NSString *)name action:(dispatch_block_t)action;


@end

NS_ASSUME_NONNULL_END
