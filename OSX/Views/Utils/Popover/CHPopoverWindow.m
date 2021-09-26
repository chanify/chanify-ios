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
@property (nonatomic, readonly, strong) CHPageView *pageView;

@end

@implementation CHPopoverWindow

+ (instancetype)windowWithPage:(CHPageView *)page {
    return [[self.class alloc] initWithPage:page];
}

- (instancetype)initWithPage:(CHPageView *)page {
    NSWindowStyleMask styleMask = NSWindowStyleMaskTitled|NSWindowStyleMaskFullSizeContentView;
    if (self = [super initWithContentRect:NSZeroRect styleMask:styleMask backing:NSBackingStoreBuffered defer:NO]) {
        _pageView = page;
        page.delegate = self;
        
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
        
        [view addSubview:page];
        
        CHLabel *titleLabel = [CHLabel new];
        [view addSubview:(_titleLabel = titleLabel)];
        [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.centerX.equalTo(view);
            make.height.mas_equalTo(28);
        }];
        titleLabel.textColor = theme.labelColor;
        titleLabel.font = theme.textFont;
        [self titleUpdated];

        [page mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(titleLabel.mas_bottom);
            make.left.right.bottom.equalTo(view);
        }];
        NSSize size = page.intrinsicContentSize;
        if (size.width <= 0) size.width = 400;
        if (size.height <= 0) size.height = 270;
        [self setFrame:NSMakeRect(0, 0, size.width, size.height + 30) display:YES animate:NO];
    }
    return self;
}

#pragma mark - CHPageViewDelegate
- (void)titleUpdated {
    self.titleLabel.text = self.pageView.title ?: @"";
}


@end
