//
//  CHMainViewController.m
//  Chanify
//
//  Created by WizJin on 2021/5/1.
//

#import "CHMainViewController.h"
#import <Masonry/Masonry.h>
#import "CHContentItem.h"
#import "CHChannelsView.h"
#import "CHNodesView.h"
#import "CHSettingsView.h"
#import "CHTheme.h"

#define kCHMainTabBarWidth  240

@interface CHMainViewController ()

@property (nonatomic, readonly, strong) NSArray<CHContentItem *> *items;
@property (nonatomic, readonly, assign) NSInteger selectIndex;
@property (nonatomic, readonly, strong) CHView *separatorLine;
@property (nonatomic, readonly, strong) CHView *tabView;
@property (nonatomic, nullable, weak) CHBarButtonItem *rightBarButtonItem;
@property (nonatomic, nullable, weak) CHSideBarView *lastSideBarView;

@end

@implementation CHMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CHTheme *theme = CHTheme.shared;
    
    _lastSideBarView = nil;
    _rightBarButtonItem = nil;

    self.view.backgroundColor = theme.backgroundColor;

    CHView *tabView = [CHView new];
    [self.view addSubview:(_tabView = tabView)];

    CHView *separatorLine = [CHView new];
    [self.view addSubview:(_separatorLine = separatorLine)];
    separatorLine.backgroundColor = theme.separatorLineColor;

    NSPressGestureRecognizer *pressGestureRecognizer = [[NSPressGestureRecognizer alloc] initWithTarget:self action:@selector(actionClickTabItem:)];
    pressGestureRecognizer.minimumPressDuration = 0.001;
    pressGestureRecognizer.buttonMask = 1;
    pressGestureRecognizer.delaysPrimaryMouseButtonEvents = NO;
    [tabView addGestureRecognizer:pressGestureRecognizer];

    _items = @[
        [self contentItemWithTitle:@"Channels" image:@"Channel" clz:CHChannelsView.class],
        [self contentItemWithTitle:@"Nodes" image:@"Network" clz:CHNodesView.class],
        [self contentItemWithTitle:@"Settings" image:@"Settings" clz:CHSettingsView.class],
    ];
    CGFloat offset = 0;
    CGFloat width = kCHMainTabBarWidth / self.items.count;
    for (CHContentItem *item in self.items) {
        [item mas_updateConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.tabView).offset(offset);
            make.width.mas_equalTo(width);
        }];
        offset += width;
    }
    _selectIndex = -1;
    self.selectIndex = 0;
}

- (void)viewDidLayout {
    [super viewDidLayout];
    [self updateLayout];
}

- (void)viewDidAppear {
    [super viewDidAppear];
    [self.lastSideBarView viewDidAppear:YES];
    [self.contentView viewDidAppear:YES];
}

- (void)viewDidDisappear {
    [self.lastSideBarView viewDidDisappear:YES];
    [self.contentView viewDidDisappear:YES];
    [super viewDidDisappear];
}

- (nullable CHPageView *)topContentView {
    return self.contentView.topContentView;
}

- (void)restDetailViewController {
    [self.contentView resetContentView];
}

- (void)pushPage:(CHPageView *)page animate:(BOOL)animate reset:(BOOL)reset {
    [self.contentView pushPage:page animate:animate reset:reset];
}

#pragma mark - Action Metrhods
- (void)actionClickTabItem:(NSPressGestureRecognizer *)sender {
    NSPoint pt = [sender locationInView:self.tabView];
    NSInteger selectedIndex = 0;
    for (CHContentItem *item in self.items) {
        if (NSPointInRect(pt, item.frame)) {
            self.selectIndex = selectedIndex;
            break;
        }
        selectedIndex++;
    }
}

#pragma mark - Private Methods
- (CHContentItem *)contentItemWithTitle:(NSString *)title image:(NSString *)image clz:(Class)clz {
    CHContentItem *item = [CHContentItem itemWithTitle:title image:image clz:clz];
    [self.tabView addSubview:item];
    [item mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.tabView);
        make.height.mas_equalTo(38);
    }];
    return item;
}

- (nullable CHContentItem *)selectedItem {
    NSInteger index = self.selectIndex;
    if (index >= 0 && index < self.items.count) {
        return [self.items objectAtIndex:index];
    }
    return nil;
}

- (nullable CHSideBarView *)sidebarView {
    CHSideBarView *sideBarView = [self.selectedItem sidebarView];
    if (sideBarView != nil) {
        if (sideBarView != self.lastSideBarView) {
            if (self.lastSideBarView != nil) {
                self.lastSideBarView.hidden = YES;
                [self.lastSideBarView viewDidDisappear:YES];
            }
            _lastSideBarView = sideBarView;
            if (sideBarView.superview != self.view) {
                [self.view addSubview:sideBarView];
            }
            self.lastSideBarView.hidden = NO;
            [self.lastSideBarView viewDidAppear:YES];
        }
        return sideBarView;
    }
    return nil;
}

- (nullable CHContentView *)contentView {
    CHContentView *contentView = [self.selectedItem contentView];
    if (contentView != nil) {
        if (contentView.superview != self.view) {
            [self.view addSubview:contentView];
        }
        return contentView;
    }
    return nil;
}

- (void)setSelectIndex:(NSInteger)selectIndex {
    if (_selectIndex != selectIndex) {
        [self.selectedItem setSelected:NO];
        [self.sidebarView setHidden:YES];
        [self.contentView setHidden:YES];
        [self.contentView viewDidDisappear:NO];

        _selectIndex = selectIndex;
        
        CHBarButtonItem *rightBarButtonItem = self.sidebarView.rightBarButtonItem;
        if (self.rightBarButtonItem != rightBarButtonItem) {
            if (self.rightBarButtonItem != nil) {
                [self.rightBarButtonItem removeFromSuperview];
                _rightBarButtonItem = nil;
            }
            _rightBarButtonItem = rightBarButtonItem;
            if (self.rightBarButtonItem != nil) {
                [self.view addSubview:self.rightBarButtonItem];
            }
        }
        
        [self.selectedItem setSelected:YES];
        [self.sidebarView setHidden:NO];
        [self.contentView setHidden:NO];
        [self updateLayout];
        [self.contentView viewDidAppear:NO];
    }
}

- (void)updateLayout {
    NSRect frame = self.view.bounds;
    self.tabView.frame = NSMakeRect(0, 0, kCHMainTabBarWidth, 60);
    self.sidebarView.frame = NSMakeRect(0, 60, kCHMainTabBarWidth, NSHeight(frame) - 60 - 58);
    self.separatorLine.frame = NSMakeRect(kCHMainTabBarWidth, 0, 1, NSHeight(frame));
    self.contentView.frame = NSMakeRect(kCHMainTabBarWidth + 1, 0, NSWidth(frame) - kCHMainTabBarWidth - 1, NSHeight(frame));
    CHBarButtonItem *barButtonItem = self.rightBarButtonItem;
    if (barButtonItem != nil) {
        NSSize size = barButtonItem.bounds.size;
        barButtonItem.frame = NSMakeRect(kCHMainTabBarWidth - (48 + size.width) / 2, NSHeight(frame) - (58 + size.height) / 2, size.width, size.height);
    }
}


@end
