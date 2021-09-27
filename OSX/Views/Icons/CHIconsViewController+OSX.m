//
//  CHIconsViewController+OSX.m
//  OSX
//
//  Created by WizJin on 2021/9/18.
//

#import "CHIconsViewController.h"

@interface CHIconsViewController ()

@property (nonatomic, readonly, strong) NSString *iconImage;

@end

@implementation CHIconsViewController

- (instancetype)initWithIcon:(NSString *)icon {
    if (self = [super init]) {
        _iconImage = icon;
        self.title = @"Icon".localized;
    }
    return self;
}

- (CGSize)calcContentSize {
    return CGSizeMake(400, 500);
}

@end
