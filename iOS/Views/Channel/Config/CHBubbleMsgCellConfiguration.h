//
//  CHBubbleMsgCellConfiguration.h
//  Chanify
//
//  Created by WizJin on 2021/3/26.
//

#import "CHMsgCellConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHBubbleMsgCellConfiguration : CHMsgCellConfiguration

@property (nonatomic, readonly, assign) CGRect bubbleRect;

- (instancetype)initWithMID:(NSString *)mid bubbleRect:(CGRect)bubbleRect;
- (void)setNeedRecalcContentLayout;

@end

@interface CHBubbleMsgCellContentView<Configuration: CHMsgCellConfiguration*> : CHMsgCellContentView<Configuration>

@property (class, nonatomic, readonly, strong) UIFont *textFont;
@property (class, nonatomic, readonly, strong) UIFont *titleFont;
@property (nonatomic, readonly, strong) UIView *bubbleView;


@end


NS_ASSUME_NONNULL_END
