//
//  CHImagesViewController.m
//  iOS
//
//  Created by WizJin on 2021/5/18.
//

#import "CHImagesViewController.h"
#import "CHPreviewController.h"
#import "CHImageTableViewCell.h"
#import "CHWebImageManager.h"
#import "CHLogic+iOS.h"
#import "CHRouter.h"

@implementation CHImagesViewController

- (instancetype)init {
    if (self = [super initWithCellClass:CHImageTableViewCell.class manager:CHLogic.shared.webImageManager]) {
        self.title = @"Images".localized;
        self.name = @"image";
        self.pageSize = 10;
    }
    return self;
}

- (void)previewURL:(NSURL *)url atView:(UIView *)view {
    CHPreviewItem *item = [CHPreviewItem itemWithURL:url title:@"" uti:@"public.jpeg"];
    CHPreviewController *vc = [CHPreviewController previewImages:@[item] selected:0];
    [CHRouter.shared presentSystemViewController:vc animated:YES];
}


@end
