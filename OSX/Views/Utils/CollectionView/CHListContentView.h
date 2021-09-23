//
//  CHListContentView.h
//  OSX
//
//  Created by WizJin on 2021/9/18.
//

#import "CHUI.h"

NS_ASSUME_NONNULL_BEGIN

#define CHListContentViewMargin 20

@class CHListContentConfiguration;

@interface CHListContentView : CHView<CHContentView>

@property (nonatomic, copy) id<CHContentConfiguration> configuration;

- (instancetype)initWithConfiguration:(CHListContentConfiguration *)configuration;
- (NSLayoutGuide *)textLayoutGuide;
- (NSLayoutGuide *)secondaryTextLayoutGuide;


@end

NS_ASSUME_NONNULL_END
