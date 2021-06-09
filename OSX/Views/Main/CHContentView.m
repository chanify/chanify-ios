//
//  CHContentView.m
//  OSX
//
//  Created by WizJin on 2021/6/1.
//

#import "CHContentView.h"
#import "CHTheme.h"

@interface CHContentView ()

@property (nonatomic, nullable, weak) NSView *appearView;

@end

@implementation CHContentView

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        _contentView = nil;
        _appearView = nil;
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
        if ([self.contentView respondsToSelector:@selector(viewDidAppear)]) {
            [self.contentView performSelector:@selector(viewDidAppear)];
        }
        
    }
}

- (void)viewDidDisappear {
    if (_appearView == self.contentView) {
        _appearView = nil;
        if ([self.contentView respondsToSelector:@selector(viewDidDisappear)]) {
            [self.contentView performSelector:@selector(viewDidDisappear)];
        }
    }
}


@end
