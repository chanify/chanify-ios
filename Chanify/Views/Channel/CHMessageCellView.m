//
//  CHMessageCellView.m
//  Chanify
//
//  Created by WizJin on 2021/4/15.
//

#import "CHMessageCellView.h"
#import "CHMsgCellConfiguration.h"

@implementation CHMessageCellView

- (void)updateConfigurationUsingState:(UICellConfigurationState *)state {
    [super updateConfigurationUsingState:state];
    if ([self.contentView isKindOfClass:CHMsgCellContentView.class]) {
        [(CHMsgCellContentView *)self.contentView updateConfigurationUsingState:state];
    }
}


@end
