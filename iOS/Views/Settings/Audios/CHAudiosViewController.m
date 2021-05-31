//
//  CHAudiosViewController.m
//  iOS
//
//  Created by WizJin on 2021/5/28.
//

#import "CHAudiosViewController.h"
#import "CHAudioTableViewCell.h"
#import "CHWebAudioManager.h"
#import "CHLogic+iOS.h"
#import "CHRouter+iOS.h"

@implementation CHAudiosViewController

- (instancetype)init {
    if (self = [super initWithCellClass:CHAudioTableViewCell.class manager:CHLogic.shared.webAudioManager]) {
        self.title = @"Audios".localized;
        self.name = @"audio";
        self.pageSize = 20;
    }
    return self;
}

- (void)previewURL:(NSURL *)url atView:(UIView *)view {
    if (url != nil) {
        [CHRouter.shared showShareItem:@[[NSFileManager.defaultManager URLLinkForFile:url withName:@"audio.mp3"]] sender:view handler:nil];
    }
}


@end
