//
//  NSDictionary+CHExt.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import <Foundation/NSDictionary.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (CHExt)

+ (nullable instancetype)dictionaryWithJSONData:(nullable NSData *)data;
- (NSMutableDictionary *)dictionaryWithValue:(nullable id)value forKey:(NSString *)key;
- (NSData *)json;


@end

NS_ASSUME_NONNULL_END
