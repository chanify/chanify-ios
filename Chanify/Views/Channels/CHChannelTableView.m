//
//  CHChannelTableView.m
//  Chanify
//
//  Created by WizJin on 2021/2/20.
//

#import "CHChannelTableView.h"
#import "CHTheme.h"

@implementation CHChannelTableView

- (instancetype)init {
    if (self = [super initWithFrame:CGRectZero style:UITableViewStylePlain]) {
        CHTheme *theme = CHTheme.shared;
        
        self.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 1)];
        self.backgroundColor = theme.groupedBackgroundColor;
        self.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.separatorColor = theme.groupedBackgroundColor;
        self.rowHeight = 71;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    for (UIView *subview in self.subviews) {
        if ([NSStringFromClass(subview.class) isEqualToString:@"_UITableViewCellSwipeContainerView"]) {
            UIView *button = findSubview(subview, @"UISwipeActionPullView");
            if (button != nil) {
                NSIndexPath *indexPath = [button valueForKeyPath:@"_delegate._indexPath"];
                if (indexPath != nil) {
                    UITableViewCell *cell = [self cellForRowAtIndexPath:indexPath];
                    if (cell != nil) {
                        CGRect frame = button.frame;
                        frame.size.height = CGRectGetHeight(cell.contentView.bounds);
                        button.frame = frame;
                    }
                }
            }
        }
    }
}

#pragma mark - Private Methods
static inline UIView *findSubview(UIView *view, NSString * name) {
    if (name.length > 0) {
        for (UIView *subview in view.subviews) {
            if ([NSStringFromClass([subview class]) isEqualToString:name]) {
                return subview;
            }
        }
    }
    return nil;
}


@end
