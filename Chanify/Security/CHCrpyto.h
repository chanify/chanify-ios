//
//  CHCrpyto.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHCrpyto : NSObject

+ (nullable NSData *)aesOpenWithKey:(NSData *)key data:(NSData *)data auth:(NSData *)auth;


@end

NS_ASSUME_NONNULL_END
