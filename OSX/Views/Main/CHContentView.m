//
//  CHContentView.m
//  OSX
//
//  Created by WizJin on 2021/6/1.
//

#import "CHContentView.h"
#import "CHTheme.h"

@interface CHContentView ()

@property (nonatomic, readonly, strong) CHLabel *titleLabel;
@property (nonatomic, readonly, strong) CHView *separatorLine;
@property (nonatomic, nullable, weak) CHPageView *appearView;

@end

@implementation CHContentView

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        CHTheme *theme = CHTheme.shared;
        
        _contentView = nil;
        _appearView = nil;
        self.backgroundColor = theme.backgroundColor;
        
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
    self.titleLabel.frame = NSMakeRect(16, NSHeight(frame) - 58, NSWidth(frame), 58);
    self.separatorLine.frame = NSMakeRect(0, NSHeight(frame) - 59, NSWidth(frame), 1);
    self.contentView.frame = NSMakeRect(0, 0, NSWidth(frame), NSHeight(frame) - 59);
}

- (void)setContentView:(CHPageView *)contentView {
    if (_contentView != contentView) {
        [self viewDidDisappear];
        [_contentView removeFromSuperview];
        [self addSubview:(_contentView = contentView)];
        self.needsLayout = YES;
        [self viewDidAppear];
    }
}

- (void)viewDidAppear {
    if (_appearView != self.contentView) {
        _appearView = self.contentView;
        [self.contentView viewDidAppear];
        self.titleLabel.text = [self.contentView title];
    }
}

- (void)viewDidDisappear {
    if (_appearView == self.contentView) {
        _appearView = nil;
        [self.contentView viewDidDisappear];
    }
}


@end
