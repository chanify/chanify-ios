//
//  CHMainViewController.m
//  Chanify
//
//  Created by WizJin on 2021/5/1.
//

#import "CHMainViewController.h"
#import "CHView.h"
#import "CHTheme.h"

@interface CHMainViewController ()

@end

@implementation CHMainViewController

- (void)loadView {
    CHView *view = [CHView new];
    self.view = view;
    view.backgroundColor = CHTheme.shared.backgroundColor;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}


@end
