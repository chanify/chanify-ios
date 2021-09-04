//
//  CHMainViewController.m
//  Chanify
//
//  Created by WizJin on 2021/5/1.
//

#import "CHMainViewController.h"
#import <Masonry/Masonry.h>
#import "CHTabBarView.h"
#import "CHContentView.h"

@interface CHMainViewController ()

@property (nonatomic, readonly, strong) CHTabBarView *sidebarView;
@property (nonatomic, readonly, strong) CHContentView *contentView;

@end

@implementation CHMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.view addSubview:(_sidebarView = [CHTabBarView new])];
    [self.view addSubview:(_contentView = [CHContentView new])];
    [_sidebarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.bottom.equalTo(self.view);
        make.width.mas_equalTo(240);
    }];
    [_contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.top.bottom.equalTo(self.view);
        make.left.equalTo(self.sidebarView.mas_right);
    }];
}

- (void)viewDidAppear {
    [super viewDidAppear];
    [self.sidebarView reloadData];
    [self.contentView viewDidAppear];
}

- (void)viewDidDisappear {
    [self.contentView viewDidDisappear];
    [super viewDidDisappear];
}

- (void)pushContentView:(nullable NSView *)contentView {
    self.contentView.contentView = contentView;
}

- (nullable NSView *)topContentView {
    return self.contentView.contentView;
}


@end
