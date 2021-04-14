//
//  CHMsgCellConfiguration.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHCellConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHMsgCellConfiguration : CHCellConfiguration

- (instancetype)initWithMID:(NSString *)mid;
- (CGSize)calcContentSize:(CGSize)size;


@end

@interface CHMsgCellContentView<Configuration: __kindof CHMsgCellConfiguration*> : UIView<UIContentView>

@property (nonatomic, nullable, copy) CHMsgCellConfiguration *configuration;
@property (nonatomic, nullable, weak) CHMessagesDataSource *source;

- (instancetype)initWithConfiguration:(CHMsgCellConfiguration *)configuration;
- (void)applyConfiguration:(Configuration)configuration;
- (void)setupViews;
- (UIView *)contentView;
- (void)actionClicked:(UITapGestureRecognizer *)sender;
- (NSArray<UIMenuItem *> *)menuActions;


@end

NS_ASSUME_NONNULL_END
