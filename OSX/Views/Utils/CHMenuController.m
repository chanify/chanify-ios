//
//  CHMenuController.m
//  OSX
//
//  Created by WizJin on 2021/6/8.
//

#import "CHMenuController.h"
#import "CHRouter+OSX.h"

@interface CHMenuController ()

@property (nonatomic, nullable, strong) NSMenu *menu;

@end

@implementation CHMenuController : NSObject

+ (instancetype)sharedMenuController {
    static CHMenuController *menuCtrl = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        menuCtrl = [CHMenuController new];
    });
    return menuCtrl;
}

- (instancetype)init {
    if (self = [super init]) {
        
    }
    return self;
}

- (void)showMenuFromView:(CHView *)targetView target:(CHView *)target point:(CGPoint)point {
    [self hideMenuFromView:targetView];
    if (_menu == nil) {
        [target becomeFirstResponder];
        NSMenu *menu = [[NSMenu alloc] initWithTitle:@"menu"];
        _menu = menu;
        for (NSMenuItem *item in self.menuItems) {
            [menu addItem:item];
            item.enabled = YES;
            item.target = target;
        }
        [menu popUpMenuPositioningItem:nil atLocation:point inView:targetView];
    }
}

- (BOOL)isMenuVisible {
    return NO;
}

- (void)hideMenuFromView:(CHView *)targetView {
    if (_menu != nil) {
        _menu = nil;
    }
}

@end
