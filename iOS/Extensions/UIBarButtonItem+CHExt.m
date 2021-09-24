//
//  UIBarButtonItem+CHExt.m
//  iOS
//
//  Created by WizJin on 2021/9/24.
//

#import "UIBarButtonItem+CHExt.h"
#import <UIKit/UIImage.h>

@implementation UIBarButtonItem (CHExt)

+ (instancetype)itemWithIcon:(NSString *)icon target:(id)target action:(SEL)action {
    return [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:icon] style:UIBarButtonItemStylePlain target:target action:action];
}


@end
