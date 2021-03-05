//
//  CHXLFormViewController.m
//  Chanify
//
//  Created by WizJin on 2021/2/19.
//

#import "CHXLFormViewController.h"
#import <XLForm/XLForm.h>

@implementation CHXLFormViewController

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    XLFormRowDescriptor *row = [self.form formRowAtIndex:indexPath];
    if (row.rowType == XLFormRowDescriptorTypeSelectorPush && row.action.formBlock != nil) {
        row.action.formBlock(row);
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


@end
