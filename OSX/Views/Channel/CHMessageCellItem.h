//
//  CHMessageCellItem.h
//  OSX
//
//  Created by WizJin on 2021/6/7.
//

#import "CHUI.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHTapGestureRecognizer : NSClickGestureRecognizer
- (void)requireGestureRecognizerToFail:(NSGestureRecognizer *)otherGestureRecognizer;
@end

@interface CHLongPressGestureRecognizer : NSClickGestureRecognizer
@end

@interface CHMenuController : NSObject

@property(nullable, nonatomic,copy) NSArray<CHMenuItem *> *menuItems;

+ (instancetype)sharedMenuController;
- (void)showMenuFromView:(CHView *)targetView rect:(CGRect)targetRect;
- (BOOL)isMenuVisible;
- (void)hideMenuFromView:(CHView *)targetView;

@end

@interface NSMenuItem (CHExt)

- (instancetype)initWithTitle:(NSString *)title action:(SEL)action;

@end


NS_ASSUME_NONNULL_END
