//
//  CHImagesViewController.m
//  iOS
//
//  Created by WizJin on 2021/5/18.
//

#import "CHImagesViewController.h"

@implementation CHImagesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Images".localized;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"trash"] style:UIBarButtonItemStylePlain target:self action:@selector(actionCleanup:)];
}

#pragma mark - Private Methods
- (void)actionCleanup:(id)sender {
    
}


@end
