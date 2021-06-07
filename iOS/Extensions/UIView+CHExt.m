//
//  UIView+CHExt.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "UIView+CHExt.h"
#import <UIKit/UIGraphics.h>
#import "CHDevice.h"

@implementation UIView (CHExt)

- (nullable UIImage *)snapshotImage {
    UIImage *image = nil;
    if (self != nil) {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, CHDevice.shared.scale);
        [self.layer renderInContext:UIGraphicsGetCurrentContext()];
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return image;
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    self.layer.cornerRadius = cornerRadius;
}


@end
