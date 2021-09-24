//
//  UIBarButtonItem+CHExt.h
//  iOS
//
//  Created by WizJin on 2021/9/24.
//

#import <UIKit/UIBarButtonItem.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIBarButtonItem (CHExt)

+ (instancetype)itemWithIcon:(NSString *)icon target:(id)target action:(SEL)action;


@end

NS_ASSUME_NONNULL_END
