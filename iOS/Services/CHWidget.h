//
//  CHWidget.h
//  iOS
//
//  Created by WizJin on 2021/6/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CHChannelModel;

@interface CHWidget : NSObject

+ (instancetype)shared;
- (void)reloadDB:(nullable NSString *)uid;
- (void)reloadIfNeeded;
- (void)upsertChannel:(CHChannelModel *)model;
- (void)deleteChannel:(nullable NSString *)cid;


@end

NS_ASSUME_NONNULL_END
