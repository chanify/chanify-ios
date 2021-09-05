//
//  CHNodesView.m
//  OSX
//
//  Created by WizJin on 2021/9/6.
//

#import "CHNodesView.h"
#import "CHTheme.h"

@implementation CHNodesView

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        CHTheme *theme = CHTheme.shared;
        self.backgroundColor = theme.groupedBackgroundColor;
    }
    return self;
}

- (void)reloadData {
}


@end
