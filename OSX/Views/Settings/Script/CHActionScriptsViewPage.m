//
//  CHActionScriptsViewPage.m
//  OSX
//
//  Created by WizJin on 2022/4/1.
//

#import "CHActionScriptsViewPage.h"
#import "CHTheme.h"

@implementation CHActionScriptsViewPage

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CHTheme *theme = CHTheme.shared;
    self.backgroundColor = theme.backgroundColor;
    self.title = @"Action Scripts".localized;
}


@end
