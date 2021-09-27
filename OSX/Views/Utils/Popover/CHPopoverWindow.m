//
//  CHPopoverWindow.m
//  OSX
//
//  Created by WizJin on 2021/9/26.
//

#import "CHPopoverWindow.h"
#import <Masonry/Masonry.h>
#import "CHTheme.h"

@interface CHPopoverWindow () <CHPageViewDelegate>

@property (nonatomic, readonly, strong) CHLabel *titleLabel;
@property (nonatomic, readonly, strong) NSMutableArray<CHPageView *> *pages;

@end

@implementation CHPopoverWindow

+ (instancetype)windowWithPage:(CHPageView *)page {
    return [[self.class alloc] initWithPage:page];
}

- (instancetype)initWithPage:(CHPageView *)page {
    NSWindowStyleMask styleMask = NSWindowStyleMaskTitled|NSWindowStyleMaskFullSizeContentView;
    if (self = [super initWithContentRect:NSZeroRect styleMask:styleMask backing:NSBackingStoreBuffered defer:NO]) {
        _pages = [NSMutableArray arrayWithObject:page];
        page.pageDelegate = self;
        
        CHTheme *theme = CHTheme.shared;

        self.backgroundColor = theme.backgroundColor;
        self.movableByWindowBackground = YES;
        self.titlebarAppearsTransparent = YES;
        self.releasedWhenClosed = YES;
        self.hasShadow = YES;
        
        CHView *view = [CHView new];
        self.contentView = view;

        NSButton *closeButton = [NSWindow standardWindowButton:NSWindowCloseButton forStyleMask:styleMask];
        [view addSubview:closeButton];
        [closeButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.equalTo(view).offset(7);
        }];
        closeButton.target = self;

        CHLabel *titleLabel = [CHLabel new];
        [view addSubview:(_titleLabel = titleLabel)];
        [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.centerX.equalTo(view);
            make.height.mas_equalTo(28);
        }];
        titleLabel.textColor = theme.labelColor;
        titleLabel.font = theme.textFont;

        [self pushPage:page animate:NO];
    }
    return self;
}

- (void)pushPage:(CHPageView *)page animate:(BOOL)animate {
    CHView *view = self.contentView;
    if (self.pages.count > 0) {
        CHPageView *oldPage = self.pages.firstObject;
        [oldPage removeFromSuperview];
        oldPage.pageDelegate = self;
    }
    [self.pages addObject:page];
    page.pageDelegate = self;
    [view addSubview:page];
    [self titleUpdated];
    [page mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom);
        make.left.right.bottom.equalTo(view);
    }];
    NSSize size = page.calcContentSize;
    if (size.width <= 0) size.width = 400;
    if (size.height <= 0) size.height = 270;
    [self setFrame:NSMakeRect(0, 0, size.width, size.height + 30) display:YES animate:animate];
}

- (void)popPage:(CHPageView *)page {
    if (page == self.pages.firstObject) {
        [self close];
    }
}

#pragma mark - CHPageViewDelegate
- (void)titleUpdated {
    NSString *title = nil;
    if (self.pages.count > 0) {
        title = self.pages.lastObject.title;
    }
    self.titleLabel.text = title ?: @"";
}


@end
