//
//  CHContentView.m
//  OSX
//
//  Created by WizJin on 2021/6/1.
//

#import "CHContentView.h"
#import "CHTheme.h"

@implementation CHContentView

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        _contentView = nil;
        self.backgroundColor = CHTheme.shared.backgroundColor;
    }
    return self;
}

- (void)layout {
    [super layout];
    self.contentView.frame = self.bounds;
}

- (void)setContentView:(NSView *)contentView {
    if (_contentView != contentView) {
        [_contentView removeFromSuperview];
        [self addSubview:(_contentView = contentView)];
        self.needsLayout = YES;
    }
}


@end
