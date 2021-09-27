//
//  CHSegmentedControl.h
//  OSX
//
//  Created by WizJin on 2021/9/27.
//

#import "CHUI.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHSegmentedControl : NSSegmentedControl

@property (nonatomic, assign) NSInteger selectedSegmentIndex;

- (instancetype)initWithItems:(NSArray<NSString *> *)items;
- (void)addTarget:(nullable id)target action:(SEL)action forControlEvents:(CHControlEvents)controlEvents;


@end

NS_ASSUME_NONNULL_END
