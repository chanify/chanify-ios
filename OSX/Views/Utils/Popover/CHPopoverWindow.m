//
//  CHPopoverWindow.m
//  OSX
//
//  Created by WizJin on 2021/9/26.
//

#import "CHPopoverWindow.h"
#import <Masonry/Masonry.h>
#import "CHContentView.h"
#import "CHTheme.h"

#define kCHPopoverMargin    30
#define kCHPopoverHeight    40

@interface CHPopoverWindow ()

@property (nonatomic, readonly, strong) CHContentView *pagesView;

@end

@implementation CHPopoverWindow

+ (instancetype)windowWithPage:(CHPageView *)page {
    return [[self.class alloc] initWithPage:page];
}

- (instancetype)initWithPage:(CHPageView *)page {
    NSWindowStyleMask styleMask = NSWindowStyleMaskTitled|NSWindowStyleMaskFullSizeContentView;
    if (self = [super initWithContentRect:NSZeroRect styleMask:styleMask backing:NSBackingStoreBuffered defer:NO]) {
        CHTheme *theme = CHTheme.shared;

        self.backgroundColor = theme.backgroundColor;
        self.movableByWindowBackground = YES;
        self.titlebarAppearsTransparent = YES;
        self.releasedWhenClosed = YES;
        self.hasShadow = YES;
        
        CHView *view = [CHView new];
        self.contentView = view;
        
        CHContentView *pagesView = [CHContentView new];
        [view addSubview:(_pagesView = pagesView)];
        [pagesView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(view);
        }];
        pagesView.titleLabel.alignment = NSTextAlignmentCenter;
        pagesView.headerMargin = kCHPopoverMargin;
        pagesView.headerHeight = kCHPopoverHeight;

        NSButton *closeButton = [NSWindow standardWindowButton:NSWindowCloseButton forStyleMask:styleMask];
        [view addSubview:closeButton];
        [closeButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.equalTo(view).offset(7);
        }];
        closeButton.target = self;

        [self pushPage:page animate:NO];
    }
    return self;
}

- (void)pushPage:(CHPageView *)page animate:(BOOL)animate {
    [self.pagesView pushPage:page animate:animate reset:NO];
    NSSize size = page.calcContentSize;
    if (size.width <= 0) size.width = 400;
    if (size.height <= 0) size.height = 300 - kCHPopoverHeight;
    [self setFrame:NSMakeRect(0, 0, size.width, size.height + kCHPopoverHeight) display:YES animate:animate];
}

- (void)popPage:(CHPageView *)page {
    if (self.pagesView.pageCount <= 1) {
        [self close];
    } else {
        [self.pagesView popPage:page animate:YES];
    }
}


@end
