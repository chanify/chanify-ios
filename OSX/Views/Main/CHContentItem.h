//
//  CHContentItem.h
//  OSX
//
//  Created by WizJin on 2021/9/6.
//

#import "CHSideBarView.h"
#import "CHContentView.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHContentItem : CHView

@property (nonatomic, assign) BOOL selected;

+ (instancetype)itemWithTitle:(NSString *)title image:(NSString *)icon clz:(Class)clz;
- (nullable CHSideBarView *)sidebarView;
- (nullable CHContentView *)contentView;


@end

NS_ASSUME_NONNULL_END
