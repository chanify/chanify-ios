//
//  CHFilesViewController.m
//  iOS
//
//  Created by WizJin on 2021/5/18.
//

#import "CHFilesViewController.h"
#import "CHPreviewController.h"
#import "CHFileTableViewCell.h"
#import "CHWebFileManager.h"
#import "CHRouter.h"
#import "CHLogic.h"

@implementation CHFilesViewController

- (instancetype)init {
    if (self = [super initWithCellClass:CHFileTableViewCell.class manager:CHLogic.shared.webFileManager]) {
        self.title = @"Files".localized;
        self.name = @"file";
        self.pageSize = 20;
    }
    return self;
}

- (void)previewURL:(NSURL *)url atView:(UIView *)view {
    CHPreviewController *vc = [CHPreviewController previewFile:url];
    [CHRouter.shared presentSystemViewController:vc animated:YES];
}


@end
