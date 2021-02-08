//
//  CHAcknowledgementsViewController.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHAcknowledgementsViewController.h"
#import <Masonry/Masonry.h>
#import "CHTheme.h"

@implementation CHAcknowledgementsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Acknowledgements".localized;
    
    CHTheme *theme = CHTheme.shared;

    UIScrollView *contentView = [UIScrollView new];
    [self.view addSubview:contentView];
    contentView.alwaysBounceVertical = YES;
    [contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    UIView *lastView = nil;
    UIFont *titleFont = [UIFont boldSystemFontOfSize:18];
    UIFont *contextFont = [UIFont systemFontOfSize:14];

    NSURL *url = [[NSBundle.mainBundle URLForResource:@"Settings" withExtension:@"bundle"] URLByAppendingPathComponent:@"Acknowledgements.plist"];
    NSDictionary *data = [self loadPlist:url];
    for (NSDictionary *item in [data valueForKey:@"PreferenceSpecifiers"]) {
        NSString *title = [item valueForKey:@"Title"];
        if (title.length > 0) {
            if (lastView == nil) {
                lastView = [UIView new];
                [contentView addSubview:lastView];
                [lastView mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.top.equalTo(contentView);
                    make.left.equalTo(self.view).offset(20);
                    make.right.equalTo(self.view).offset(-20);
                }];
            } else {
                UILabel *label = [UILabel new];
                [contentView addSubview:label];
                label.font = titleFont;
                label.text = title;
                label.textColor = theme.labelColor;
                [label mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.top.equalTo(lastView.mas_bottom).offset(20);
                    make.left.right.equalTo(lastView);
                }];
                lastView = label;
            }
        }
        NSString *context = [item valueForKey:@"FooterText"];
        if (context.length > 0) {
            UILabel *label = [UILabel new];
            [contentView addSubview:label];
            label.numberOfLines = 0;
            label.font = contextFont;
            label.textColor = theme.minorLabelColor;
            label.text = [context stringByAppendingString:@"\n"];
            [label mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(lastView.mas_bottom).offset(20);
                make.left.right.equalTo(lastView);
            }];
            lastView = label;
        }
    }
    [lastView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(contentView);
    }];
}

#pragma mark - Private Methods
- (NSDictionary *)loadPlist:(NSURL *)url {
    NSError *error = nil;
    NSDictionary *result = nil;
    NSData *data = [NSData dataWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:&error];
    if (error == nil && data.length > 0) {
        NSDictionary *plist = [NSPropertyListSerialization propertyListWithData:data options:0 format:nil error:&error];
        if (error == nil) {
            result = plist;
        }
    }
    return result;
}


@end
