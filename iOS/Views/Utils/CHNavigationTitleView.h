//
//  CHNavigationTitleView.h
//  Chanify
//
//  Created by WizJin on 2021/4/17.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHNavigationTitleView : UIView

@property (nonatomic, strong) NSString *title;

- (instancetype)initWithNavigationController:(UINavigationController *)vc;


@end

NS_ASSUME_NONNULL_END
