//
//  CHViewController.m
//  OSX
//
//  Created by WizJin on 2021/6/1.
//

#import "CHViewController.h"

@implementation CHViewController

- (void)loadView {
    if (!self.isViewLoaded) {
        self.view = [NSView new];
    }
}

- (BOOL)isEqualToViewController:(__kindof CHViewController *)rhs {
    // TODO: fix this
    return YES;
}


@end
