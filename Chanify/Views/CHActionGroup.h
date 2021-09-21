//
//  CHActionGroup.h
//  iOS
//
//  Created by WizJin on 2021/5/13.
//

#import "CHUI.h"
#import "CHActionItemModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CHActionGroupDelegate <NSObject>
- (void)actionGroupSelected:(nullable CHActionItemModel *)item;
@end

@interface CHActionGroup : CHView

@property (class, nonatomic, readonly, assign) CGFloat defaultHeight;
@property (nonatomic, nullable, weak) id<CHActionGroupDelegate> delegate;
@property (nonatomic, nullable, strong) NSArray<CHActionItemModel *> *actions;
@property (nonatomic, assign) CGFloat lineWidth;


@end

NS_ASSUME_NONNULL_END
