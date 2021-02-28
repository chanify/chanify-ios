//
//  CHTableViewCell.m
//  Chanify
//
//  Created by WizJin on 2021/2/25.
//

#import "CHTableViewCell.h"

@implementation CHTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        UIBackgroundConfiguration *backgroundConfiguration = UIBackgroundConfiguration.listGroupedCellConfiguration;
        backgroundConfiguration.backgroundInsets = NSDirectionalEdgeInsetsMake(0, 0, 1, 0);
        self.backgroundConfiguration = backgroundConfiguration;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect frame = self.bounds;
    frame.size.height -= 1;
    self.contentView.frame = frame;
}


@end
