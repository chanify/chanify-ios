//
//  CHThumbnailModel.h
//  Chanify
//
//  Created by WizJin on 2021/3/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHThumbnailModel : NSObject

@property (nonatomic, readonly, assign) NSUInteger width;
@property (nonatomic, readonly, assign) NSUInteger height;
@property (nonatomic, readonly, nullable, strong) NSData *preview;

+ (instancetype)thumbnailWithWidth:(NSUInteger)width height:(NSUInteger)height preview:(nullable NSData *)preview;


@end

NS_ASSUME_NONNULL_END
