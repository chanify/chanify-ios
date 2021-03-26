//
//  CHSoundsViewController.m
//  Chanify
//
//  Created by WizJin on 2021/3/26.
//

#import "CHSoundsViewController.h"
#import "CHTheme.h"

@interface CHSoundsViewController ()

@end

@implementation CHSoundsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Sound".localized;
    self.view.backgroundColor = CHTheme.shared.groupedBackgroundColor;
}


@end
