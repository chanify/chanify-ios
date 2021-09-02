//
//  CHTabBarView.m
//  OSX
//
//  Created by WizJin on 2021/9/1.
//

#import "CHTabBarView.h"
#import <Masonry/Masonry.h>
#import "CHChannelsView.h"
#import "CHTheme.h"

@interface CHTabBarView ()

@property (nonatomic, readonly, strong) CHChannelsView *channelsView;

@end

@implementation CHTabBarView

- (instancetype)initWithFrame:(NSRect)frameRect {
    frameRect.size.height = MAX(frameRect.size.height, 120);
    if (self = [super initWithFrame:frameRect]) {
        CHTheme *theme = CHTheme.shared;
        
        self.backgroundColor = theme.backgroundColor;
        
        CHView *tabView = [CHView new];
        [self addSubview:tabView];
        [tabView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.bottom.equalTo(self);
            make.height.mas_equalTo(60);
        }];
        
        NSButton *button = [NSButton buttonWithImage:[CHImage imageNamed:@"Channel"] target:self action:@selector(actionTabbarClicked:)];
        [tabView addSubview:button];
        [button mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(tabView);
            make.left.equalTo(tabView).offset(10);
            make.height.mas_equalTo(40);
        }];
        
        CHChannelsView *channelsView = [CHChannelsView new];
        [self addSubview:(_channelsView = channelsView)];
        [channelsView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.equalTo(self);
            make.bottom.equalTo(tabView.mas_top);
        }];
    }
    return self;
}

- (void)reloadData {
    [self.channelsView reloadData];
}

#pragma mark - Action Methods
- (void)actionTabbarClicked:(id)sender {
    
}


@end
