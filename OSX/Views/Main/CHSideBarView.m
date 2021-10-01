//
//  CHSideBarView.m
//  OSX
//
//  Created by WizJin on 2021/9/6.
//

#import "CHSideBarView.h"

@interface CHSideBarView ()

@property (nonatomic, readonly, assign) BOOL isLoad;

@end

@implementation CHSideBarView

- (void)viewWillMoveToSuperview:(NSView *)newSuperview {
    if (!self.isLoad) {
        _isLoad = YES;
        [self viewDidLoad];
    }
    [super viewWillMoveToSuperview:newSuperview];
}

- (void)viewDidLoad {
}

- (void)viewDidAppear:(BOOL)animated {
}

- (void)viewDidDisappear:(BOOL)animated {
}


@end
