//
//  CHContentView.m
//  OSX
//
//  Created by WizJin on 2021/6/1.
//

#import "CHContentView.h"
#import "CHTheme.h"

@interface CHContentView () <CHPageViewDelegate>

@property (nonatomic, readonly, strong) NSMutableArray<CHPageView *>    *pages;
@property (nonatomic, readonly, strong) CHBarButtonItem *backBarButtonItem;
@property (nonatomic, nullable, weak) CHBarButtonItem *rightBarButtonItem;
@property (nonatomic, readonly, strong) CHView *separatorLine;
@property (nonatomic, nullable, weak) CHPageView *appearView;

@end

@implementation CHContentView

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        CHTheme *theme = CHTheme.shared;

        _headerMargin = 16;
        _headerHeight = 58;
        _pages = [NSMutableArray new];
        _appearView = nil;
        _rightBarButtonItem = nil;
        self.backgroundColor = theme.backgroundColor;

        CHBarButtonItem *backBarButtonItem = [CHBarButtonItem itemWithIcon:@"chevron.backward" target:self action:@selector(actionPopPage:)];
        [self addSubview:(_backBarButtonItem = backBarButtonItem)];

        CHLabel *titleLabel = [CHLabel new];
        [self addSubview:(_titleLabel = titleLabel)];
        titleLabel.font = [CHFont systemFontOfSize:16];
        
        CHView *separatorLine = [CHView new];
        [self addSubview:(_separatorLine = separatorLine)];
        separatorLine.backgroundColor = theme.separatorLineColor;
    }
    return self;
}

- (void)layout {
    [super layout];
    NSRect frame = self.bounds;
    CGFloat offset = self.headerMargin;
    if(self.pages.count <= 1) {
        self.backBarButtonItem.hidden = YES;
    } else {
        NSSize size = NSMakeSize(26, 30);
        self.backBarButtonItem.hidden = NO;
        self.backBarButtonItem.frame = NSMakeRect(offset - 4, NSHeight(frame) - (self.headerHeight + size.height) / 2, size.width, size.height);
        offset += size.width + 4;
    }
    self.titleLabel.frame = NSMakeRect(offset, NSHeight(frame) - self.headerHeight, NSWidth(frame) - offset * 2, self.headerHeight);
    self.separatorLine.frame = NSMakeRect(0, NSHeight(frame) - self.headerHeight - 1, NSWidth(frame), 1);
    self.topContentView.frame = NSMakeRect(0, 0, NSWidth(frame), NSHeight(frame) - self.headerHeight - 1);
    CHBarButtonItem *barButtonItem = self.rightBarButtonItem;
    if (barButtonItem != nil) {
        NSSize size = barButtonItem.bounds.size;
        barButtonItem.frame = NSMakeRect(NSWidth(frame) - (self.headerHeight + size.width) / 2, NSHeight(frame) - (self.headerHeight + size.height) / 2, size.width, size.height);
    }
}

- (void)resetContentView {
    [self popPage:self.pages.firstObject animate:YES];
}

- (NSInteger)pageCount {
    return self.pages.count;
}

- (nullable CHPageView *)topContentView {
    return self.pages.lastObject;
}

- (void)pushPage:(nullable CHPageView *)page animate:(BOOL)animate reset:(BOOL)reset {
    if (page != nil) {
        if (!reset) {
            [self preRemovePage:self.topContentView];
        } else {
            while (self.pages.count > 0) {
                CHPageView *last = self.pages.lastObject;
                [self preRemovePage:last];
                [self.pages removeObject:last];
            }
        }
        [self.pages addObject:page];
        [self resetTopPage];
        self.needsLayout = YES;
    }
}

- (void)popPage:(nullable CHPageView *)page animate:(BOOL)animate {
    if (page != nil) {
        while (self.pages.count > 0) {
            CHPageView *last = self.pages.lastObject;
            [self preRemovePage:last];
            [self.pages removeObject:last];
            if (last == page) {
                [self resetTopPage];
                break;
            }
        }
        self.needsLayout = YES;
    }
}

- (void)viewDidAppear {
    if (_appearView != self.topContentView) {
        _appearView = self.topContentView;
        [self.topContentView viewDidAppear];
        self.titleLabel.text = [self.topContentView title] ?: @"";
    }
}

- (void)viewDidDisappear {
    if (_appearView == self.topContentView) {
        _appearView = nil;
        [self.topContentView viewDidDisappear];
    }
}

#pragma mark - CHPageViewDelegate
- (void)titleUpdated {
    self.titleLabel.text = self.topContentView.title ?: @"";
}

#pragma mark - Action Methods
- (void)actionPopPage:(id)sender {
    if (self.pages.count > 1) {
        [self popPage:self.pages.lastObject animate:YES];
    }
}

#pragma mark - Private Methods
- (void)preRemovePage:(CHPageView *)page {
    if (page != nil) {
        [page viewDidDisappear];
        page.pageDelegate = nil;
        [page removeFromSuperview];
        if (_appearView == page) {
            _appearView = nil;
            [self.topContentView viewDidDisappear];
        }
        if (page == self.topContentView) {
            self.titleLabel.text = @"";
            if (self.rightBarButtonItem != nil) {
                [self.rightBarButtonItem removeFromSuperview];
                _rightBarButtonItem = nil;
            }
        }
    }
}

- (void)resetTopPage {
    CHPageView *page = self.topContentView;
    page.pageDelegate = self;
    [self addSubview:page];
    if (_appearView != page) {
        _appearView = page;
        [page viewDidAppear];
        self.titleLabel.text = page.title ?: @"";
    }
    if (self.rightBarButtonItem != page.rightBarButtonItem) {
        if (self.rightBarButtonItem != nil) {
            [self.rightBarButtonItem removeFromSuperview];
        }
        _rightBarButtonItem = page.rightBarButtonItem;
        if (self.rightBarButtonItem != nil) {
            [self addSubview:self.rightBarButtonItem];
        }
    }
}

@end
