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
+ (instancetype)tokenWithTimeOffset:(NSTimeInterval)timeOffset;
+ (instancetype)tokenWithDate:(NSDate *)date;
+ (instancetype)defaultToken;
+ (nullable instancetype)tokenWithString:(NSString *)value;
- (NSDate *)expired;
- (NSData *)channel;
- (void)setChannel:(NSData *)channel;
- (void)setNode:(CHNodeModel *)node;
- (void)setDataHash:(nullable NSData *)data;
- (NSString *)formatString:(nullable NSString *)source direct:(BOOL)direct;


@end

NS_ASSUME_NONNULL_END
