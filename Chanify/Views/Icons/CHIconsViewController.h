//
//  CHIconsViewController.h
//  Chanify
//
//  Created by WizJin on 2021/3/7.
//

#import "CHViewPage.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CHIconsViewControllerDelegate <NSObject>
- (void)iconChanged:(NSString *)icon;
@end

@interface CHIconsViewController : CHViewPage

@property (nonatomic, nullable, weak) id<CHIconsViewControllerDelegate> delegate;

- (instancetype)initWithIcon:(NSString *)icon;


@end

NS_ASSUME_NONNULL_END
