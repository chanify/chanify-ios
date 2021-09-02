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

#define kCHMinSplitPosition     240
#define kCHMaxSplitPosition     400

@interface CHMainViewController () <NSSplitViewDelegate>

@property (nonatomic, readonly, strong) CHTabBarView *sidebarView;
@property (nonatomic, readonly, strong) CHContentView *contentView;

@end

@implementation CHMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSSplitView *splitView = [NSSplitView new];
    [self.view addSubview:splitView];
    [splitView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    splitView.dividerStyle = NSSplitViewDividerStyleThin;
    splitView.vertical = YES;
    splitView.delegate = self;
    [splitView addSubview:(_sidebarView = [CHTabBarView new])];
    [splitView addSubview:(_contentView = [CHContentView new])];
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

#pragma mark - NSSplitViewDelegate
- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex {
    return kCHMinSplitPosition;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex {
    return kCHMaxSplitPosition;
}

- (void)splitViewWillResizeSubviews:(NSNotification *)notification {
    NSSplitView *splitView = (NSSplitView *)notification.object;
    NSRect frame = splitView.bounds;
    CGFloat position = MAX(MIN(self.sidebarView.frame.size.width, frame.size.width/2), kCHMinSplitPosition);
    self.sidebarView.frame = CGRectMake(0, 0, position, frame.size.height);
    CGFloat divider = splitView.dividerThickness;
    self.contentView.frame = CGRectMake(position + divider, 0, frame.size.width - position - divider, frame.size.height);
}


@end
