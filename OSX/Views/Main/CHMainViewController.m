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
#import "CHTheme.h"

#define kCHMainTabBarWidth  240

@interface CHMainViewController ()

@property (nonatomic, readonly, strong) NSArray<CHContentItem *> *items;
@property (nonatomic, readonly, assign) NSInteger selectIndex;
@property (nonatomic, readonly, strong) CHView *tabView;

@end

@implementation CHMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = CHTheme.shared.backgroundColor;
    
    CHView *tabView = [CHView new];
    [self.view addSubview:(_tabView = tabView)];

    NSPressGestureRecognizer *pressGestureRecognizer = [[NSPressGestureRecognizer alloc] initWithTarget:self action:@selector(actionClickTabItem:)];
    pressGestureRecognizer.minimumPressDuration = 0.001;
    pressGestureRecognizer.buttonMask = 1;
    pressGestureRecognizer.delaysPrimaryMouseButtonEvents = NO;
    [tabView addGestureRecognizer:pressGestureRecognizer];

    CHContentItem *item1 = [CHContentItem itemWithTitle:@"Channels" image:@"Channel" clz:CHChannelsView.class];
    [tabView addSubview:item1];
    [item1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(tabView);
        make.left.equalTo(tabView);
        make.size.mas_equalTo(NSMakeSize(74, 38));
    }];
    CHContentItem *item2 = [CHContentItem itemWithTitle:@"Nodes" image:@"Network" clz:CHNodesView.class];
    [tabView addSubview:item2];
    [item2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(tabView);
        make.centerX.equalTo(tabView);
        make.size.mas_equalTo(NSMakeSize(74, 38));
    }];
    _items = @[item1, item2];
    _selectIndex = -1;
    self.selectIndex = 0;
}

- (void)viewDidLayout {
    [super viewDidLayout];
    [self updateLayout];
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
        if (sideBarView.superview != self.view) {
            [self.view addSubview:sideBarView];
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
        [self.contentView viewDidDisappear];

        _selectIndex = selectIndex;
        
        [self.selectedItem setSelected:YES];
        [self.sidebarView setHidden:NO];
        [self.contentView setHidden:NO];
        [self updateLayout];
        [self.sidebarView reloadData];
        [self.contentView viewDidAppear];
    }
}

- (void)updateLayout {
    NSRect frame = self.view.bounds;
    self.tabView.frame = NSMakeRect(0, 0, kCHMainTabBarWidth, 60);
    self.sidebarView.frame = NSMakeRect(0, 60, kCHMainTabBarWidth, NSHeight(frame) - 60);
    self.contentView.frame = NSMakeRect(kCHMainTabBarWidth, 0, NSWidth(frame) - kCHMainTabBarWidth, NSHeight(frame));
}


@end
