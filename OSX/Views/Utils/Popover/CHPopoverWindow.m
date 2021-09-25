//
//  CHPopoverWindow.m
//  OSX
//
//  Created by WizJin on 2021/9/26.
//

#import "CHPopoverWindow.h"
#import <Masonry/Masonry.h>
#import "CHTheme.h"

@interface CHPopoverWindow () <NSWindowDelegate>

@property (nonatomic, readonly, strong) CHPageView *pageView;

@end

@implementation CHPopoverWindow

+ (instancetype)windowWithPage:(CHPageView *)page {
    return [[self.class alloc] initWithPage:page];
}

- (instancetype)initWithPage:(CHPageView *)page {
    NSWindowStyleMask styleMask = NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskFullSizeContentView;
    if (self = [super initWithContentRect:NSZeroRect styleMask:styleMask backing:NSBackingStoreBuffered defer:NO]) {
        _pageView = page;
        
        CHTheme *theme = CHTheme.shared;

        self.backgroundColor = theme.backgroundColor;
        self.movableByWindowBackground = YES;
        self.titlebarAppearsTransparent = YES;
        self.releasedWhenClosed = YES;
        self.hasShadow = YES;
        self.delegate = self;
        
        CHView *view = [CHView new];
        self.contentView = view;

        CHLabel *titleLabel = [CHLabel new];
        [view addSubview:titleLabel];
        [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.centerX.equalTo(view);
            make.height.mas_equalTo(28);
        }];
        titleLabel.textColor = theme.labelColor;
        titleLabel.font = theme.textFont;
        titleLabel.text = self.pageView.title;
        [view addSubview:page];
        [page mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(titleLabel.mas_bottom);
            make.left.right.bottom.equalTo(view);
        }];
        
        [self setFrame:NSMakeRect(0, 0, 400, 300) display:YES animate:NO];
    }
    return self;
}

- (void)run {
    [NSApp runModalForWindow:self];
}

#pragma mark - NSWindowDelegate
- (BOOL)windowShouldClose:(NSWindow *)sender {
    [NSApp stopModalWithCode:NSModalResponseOK];
    [NSApp endSheet:self];
    return NO;
}


@end
