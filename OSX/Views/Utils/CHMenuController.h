//
//  CHMenuController.h
//  OSX
//
//  Created by WizJin on 2021/6/8.
//

#import "CHUI.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHMenuController : NSObject

@property(nullable, nonatomic,copy) NSArray<CHMenuItem *> *menuItems;

+ (instancetype)sharedMenuController;
- (void)showMenuFromView:(CHView *)targetView target:(id)target point:(CGPoint)point;
- (BOOL)isMenuVisible;
- (void)hideMenuFromView:(CHView *)targetView;


@end

NS_ASSUME_NONNULL_END
