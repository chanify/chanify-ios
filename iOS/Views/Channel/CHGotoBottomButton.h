//
//  CHGotoBottomButton.h
//  iOS
//
//  Created by wizjin on 2023/8/5.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHGotoBottomButton : UIView

@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) BOOL hasUnread;

- (instancetype)initWithTarget:(id)target action:(SEL)action;


@end

NS_ASSUME_NONNULL_END
