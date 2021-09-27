//
//  CHPageView.m
//  OSX
//
//  Created by WizJin on 2021/9/6.
//

#import "CHPageView.h"
#import "CHPopoverWindow.h"
#import "CHTheme.h"

@interface CHPageView ()

@property (nonatomic, readonly, assign) BOOL isLoad;

@end

@implementation CHPageView

- (instancetype)initWithParameters:(NSDictionary *)params {
    if (self = [super init]) {
    }
    return self;
}

- (BOOL)isEqualWithParameters:(NSDictionary *)params {
    return NO;
}

- (void)viewWillMoveToSuperview:(NSView *)newSuperview {
    if (!self.isLoad) {
        _isLoad = YES;
        [self viewDidLoad];
    }
    [super viewWillMoveToSuperview:newSuperview];
}

- (CHView *)view {
    return self;
}

- (void)viewDidLoad {
}

- (void)viewDidAppear {
}

- (void)viewDidDisappear {
}

- (void)setTitle:(NSString *)title {
    if (_title != title) {
        _title = title;
        if (self.pageDelegate != nil) {
            [self.pageDelegate titleUpdated];
        }
    }
}

- (CGSize)calcContentSize {
    return CGSizeZero;
}

- (void)closeAnimated:(BOOL)animated completion: (void (^ __nullable)(void))completion {
    if ([self.window isKindOfClass:CHPopoverWindow.class]) {
        [(CHPopoverWindow *)self.window popPage:self];
        if (completion != nil) {
            dispatch_main_async(completion);
        }
    }
}


@end
