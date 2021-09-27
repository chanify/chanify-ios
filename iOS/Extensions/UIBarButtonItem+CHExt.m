//
//  UIBarButtonItem+CHExt.m
//  iOS
//
//  Created by WizJin on 2021/9/24.
//

#import "UIBarButtonItem+CHExt.h"
#import <UIKit/UIImage.h>

@implementation UIBarButtonItem (CHExt)

+ (instancetype)itemDoneWithTarget:(id)target action:(SEL)action {
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:target action:action];
}

+ (instancetype)itemWithTitle:(NSString *)title target:(id)target action:(SEL)action {
    return [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:target action:action];
}

+ (instancetype)itemWithIcon:(NSString *)icon target:(id)target action:(SEL)action {
    return [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:icon] style:UIBarButtonItemStylePlain target:target action:action];
}


@end
