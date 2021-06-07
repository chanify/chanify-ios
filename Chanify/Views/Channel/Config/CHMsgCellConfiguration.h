//
//  CHMsgCellConfiguration.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHCellConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CHMessageSource <NSObject>
- (void)setNeedRecalcLayoutItem:(CHCellConfiguration *)cell;
- (void)beginEditingWithItem:(CHCellConfiguration *)cell;
- (void)previewImageWithMID:(NSString *)mid;
- (BOOL)isEditing;
@end

@interface CHMsgCellConfiguration : CHCellConfiguration

- (instancetype)initWithMID:(NSString *)mid;
- (CGSize)calcSize:(CGSize)size;
- (CGSize)calcContentSize:(CGSize)size;


@end

@interface CHMsgCellContentView<Configuration: __kindof CHMsgCellConfiguration*> : CHView<CHContentView>

@property (nonatomic, nullable, copy) CHMsgCellConfiguration *configuration;
@property (nonatomic, nullable, weak) id<CHMessageSource> source;

- (instancetype)initWithConfiguration:(CHMsgCellConfiguration *)configuration;
- (void)applyConfiguration:(Configuration)configuration;
- (void)setupViews;
- (CHView *)contentView;
- (BOOL)canGestureRecognizer:(CHGestureRecognizer *)recognizer;
- (void)actionClicked:(CHTapGestureRecognizer *)sender;
- (NSArray<CHMenuItem *> *)menuActions;
- (void)updateConfigurationUsingState:(CHCellConfigurationState *)state;


@end

NS_ASSUME_NONNULL_END
