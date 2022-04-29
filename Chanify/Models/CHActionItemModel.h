//
//  CHActionItemModel.h
//  Chanify
//
//  Created by WizJin on 2021/5/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHActionItemModel : NSObject

@property (nonatomic, readonly, strong) NSString *name;
@property (nonatomic, readonly, nullable, strong) NSURL *link;

+ (instancetype)actionItemWithName:(NSString *)name link:(nullable NSURL *)link mid:(nullable NSString *)mid;
+ (nullable instancetype)actionItemWithDictionary:(NSDictionary *)info;
- (NSDictionary *)dictionary;


@end

NS_ASSUME_NONNULL_END
