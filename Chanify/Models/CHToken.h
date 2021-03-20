//
//  CHToken.h
//  Chanify
//
//  Created by WizJin on 2021/3/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CHNodeModel;

@interface CHToken : NSObject

+ (instancetype)tokenWithTimeInterval:(NSTimeInterval)timeInterval;
+ (instancetype)defaultToken;
- (void)setChannel:(NSData *)channel;
- (void)setNode:(CHNodeModel *)node;
- (NSString *)formatString:(nullable NSString *)source direct:(BOOL)direct;


@end

NS_ASSUME_NONNULL_END
