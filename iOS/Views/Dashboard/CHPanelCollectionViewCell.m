//
//  CHPanelCollectionViewCell.m
//  iOS
//
//  Created by WizJin on 2021/6/21.
//

#import "CHPanelCollectionViewCell.h"
#import "CHTheme.h"

@implementation CHPanelCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        UIBackgroundConfiguration *configuration = UIBackgroundConfiguration.clearConfiguration;
        configuration.backgroundColor = CHTheme.shared.bubbleBackgroundColor;
        configuration.cornerRadius = 8;
        self.backgroundConfiguration = configuration;
    }
    return self;
}

@end
