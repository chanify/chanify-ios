//
//  CHMsgCellConfiguration.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHCellConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHMsgCellConfiguration : CHCellConfiguration

@property (nonatomic, readonly, assign) CGRect bubbleRect;

- (instancetype)initWithMID:(NSString *)mid bubbleRect:(CGRect)bubbleRect;
- (CGSize)calcContentSize:(CGSize)size;


@end

@interface CHMsgCellContentView<Configuration: CHMsgCellConfiguration*> : UIView<UIContentView>

@property (nonatomic, nullable, copy) CHMsgCellConfiguration *configuration;
@property (nonatomic, readonly, strong) UIView *bubbleView;

- (instancetype)initWithConfiguration:(CHMsgCellConfiguration *)configuration;
- (void)applyConfiguration:(Configuration)configuration;
- (void)setupViews;


@end

NS_ASSUME_NONNULL_END
