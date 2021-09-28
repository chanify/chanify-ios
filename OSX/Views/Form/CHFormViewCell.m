//
//  CHFormViewCell.m
//  OSX
//
//  Created by WizJin on 2021/9/18.
//

#import "CHFormViewCell.h"
#import "CHForm.h"
#import "CHTheme.h"

@interface CHFormViewCell ()

@property (nonatomic, nullable, weak) NSView *rightView;

@end

@implementation CHFormViewCell

- (void)loadView {
    [super loadView];
    self.view.backgroundColor = CHTheme.shared.cellBackgroundColor;
}

- (void)setItem:(CHFormItem *)item {
    [item prepareCell:self];
    NSView *accessoryView = self.accessoryView;
    if (accessoryView == nil && self.accessoryType == CHFormViewCellAccessoryDisclosureIndicator) {
        CHImageView *imageView = [[CHImageView alloc] initWithImage:[CHImage systemImageNamed:@"chevron.right"]];
        imageView.tintColor = CHTheme.shared.lightLabelColor;
        accessoryView = imageView;
    }
    if (accessoryView != self.rightView) {
        if (self.rightView != nil) {
            [self.rightView removeFromSuperview];
        }
        _rightView = accessoryView;
        if (accessoryView != nil) {
            if (self.rightView.superview != self.view) {
                [self.view addSubview:self.rightView];
            }
        }
    }
}

- (void)setNeedsUpdateConfiguration {
    self.contentView.configuration = self.contentConfiguration;
    [self.view setNeedsUpdateConstraints:YES];
}

- (void)viewDidLayout {
    [super viewDidLayout];
    if (self.rightView != nil && self.contentView != nil) {
        NSSize size = self.rightView.intrinsicContentSize;
        NSRect frame = self.contentView.frame;
        frame.size.width -= size.width + 8;
        self.contentView.frame = frame;
        frame = self.view.bounds;
        self.rightView.frame = NSMakeRect(NSWidth(frame) - size.width - CHListContentViewMargin, 0, size.width, NSHeight(frame));
    }
}


@end
