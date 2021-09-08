//
//  CHLinksViewController.m
//  iOS
//
//  Created by WizJin on 2021/9/8.
//

#import "CHLinksViewController.h"
#import "CHLinkTableViewCell.h"
#import "CHWebLinkManager.h"
#import "CHRouter.h"
#import "CHLogic.h"

@implementation CHLinksViewController

- (instancetype)init {
    if (self = [super initWithCellClass:CHLinkTableViewCell.class manager:CHLogic.shared.webLinkManager]) {
        self.title = @"Links".localized;
        self.name = @"link";
        self.pageSize = 20;
    }
    return self;
}

- (void)previewURL:(NSURL *)url atView:(UIView *)view {
    NSDictionary *info = [CHLogic.shared.webLinkManager infoWithURL:url];
    if (info != nil) {
        NSURL *link = [[CHLogic.shared.webLinkManager infoWithURL:url] valueForKey:@"link"];
        if (link != nil) {
            [CHRouter.shared handleURL:link];
        }
    }
}


@end
