//
//  CHScriptViewController.h
//  iOS
//
//  Created by WizJin on 2022/4/23.
//

#import "CHViewPage.h"

NS_ASSUME_NONNULL_BEGIN

@class CHScriptViewController;

@protocol CHScriptViewControllerDelegate <NSObject>
- (void)scriptViewController:(CHScriptViewController *)vc script:(NSString *)script;
@end

@interface CHScriptViewController : CHViewPage

@property (nonatomic, nullable, weak) id<CHScriptViewControllerDelegate> delegate;

- (instancetype)initWithName:(NSString *)name script:(nullable NSString *)script;


@end

NS_ASSUME_NONNULL_END
