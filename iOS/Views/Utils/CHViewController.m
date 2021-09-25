//
//  CHViewController.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHViewController.h"
#import "CHTheme.h"

@implementation CHViewController

- (instancetype)init {
    if (self = [super initWithNibName:nil bundle:nil]) {
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = CHTheme.shared.backgroundColor;
}

- (BOOL)isEqualWithParameters:(NSDictionary *)params {
    return NO;
}


@end
