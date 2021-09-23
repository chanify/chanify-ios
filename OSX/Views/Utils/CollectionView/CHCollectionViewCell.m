//
//  CHCollectionViewCell.m
//  OSX
//
//  Created by WizJin on 2021/6/7.
//

#import "CHCollectionViewCell.h"
#import "CHCellConfiguration.h"

@implementation CHCollectionViewCell

- (void)loadView {
    _contentView = nil;
    self.view = [NSView new];
}

- (void)viewDidLayout {
    [super viewDidLayout];
    if (self.contentView != nil) {
        self.contentView.frame = self.view.bounds;
    }
}

- (void)setContentConfiguration:(id<CHContentConfiguration>)contentConfiguration {
    if (_contentConfiguration != contentConfiguration) {
        _contentConfiguration = contentConfiguration;
        if (_contentView != nil) {
            [_contentView removeFromSuperview];
        }
        _contentView = [self.contentConfiguration makeContentView];
        if (_contentView != nil) {
            [self.view addSubview:_contentView];
        }
    }
}

- (void)updateConfigurationUsingState:(CHCellConfigurationState *)state {
    [self.contentConfiguration updatedConfigurationForState:state];
}


@end
