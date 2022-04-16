//
//  CHTextMsgCellConfiguration.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHBubbleMsgCellConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHTextMsgCellConfiguration : CHBubbleMsgCellConfiguration

@property (nonatomic, readonly, strong) NSString *text;
@property (nonatomic, readonly, assign) CGRect textRect;
@property (nonatomic, readonly, nullable, strong) NSString *title;
@property (nonatomic, readonly, assign) CGRect titleRect;

+ (instancetype)cellConfiguration:(CHMessageModel *)model;
- (instancetype)initWithMID:(NSString *)mid text:(NSString * _Nullable)text title:(NSString * _Nullable)title textRect:(CGRect)textRect titleRect:(CGRect)titleRect bubbleRect:(CGRect)bubbleRect;


@end

@class CHLinkLabel;

@interface CHTextMsgCellContentView : CHBubbleMsgCellContentView<CHTextMsgCellConfiguration *>

@property (nonatomic, readonly, strong) CHLinkLabel *textLabel;
@property (nonatomic, readonly, strong) CHLabel *titleLabel;


@end

NS_ASSUME_NONNULL_END
