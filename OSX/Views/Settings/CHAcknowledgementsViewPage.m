//
//  CHAcknowledgementsViewPage.m
//  OSX
//
//  Created by WizJin on 2021/10/11.
//

#import "CHAcknowledgementsViewPage.h"
#import <Masonry/Masonry.h>
#import "CHTheme.h"

@interface CHAcknowledgementsViewPage ()

@property (nonatomic, readonly, strong) CHView *contentView;

@end

@implementation CHAcknowledgementsViewPage

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Acknowledgements".localized;

    CHTheme *theme = CHTheme.shared;
    
    CHView *contentView = [CHView new];
    _contentView = contentView;
    contentView.backgroundColor = theme.backgroundColor;
    
    CHView *lastView = nil;
    CHFont *titleFont = [CHFont boldSystemFontOfSize:18];
    CHFont *contextFont = theme.mediumFont;

    NSURL *url = [NSBundle.mainBundle URLForResource:@"Acknowledgements" withExtension:@"plist"];
    NSDictionary *data = [self loadPlist:url];
    for (NSDictionary *item in [data valueForKey:@"PreferenceSpecifiers"]) {
        NSString *title = [item valueForKey:@"Title"];
        if (title.length > 0) {
            if (lastView == nil) {
                lastView = [CHView new];
                [contentView addSubview:lastView];
                [lastView mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.top.equalTo(contentView);
                    make.left.equalTo(contentView).offset(20);
                    make.right.equalTo(contentView).offset(-20);
                }];
            } else {
                CHLabel *label = [CHLabel new];
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
            CHLabel *label = [CHLabel new];
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
        make.bottom.equalTo(contentView).offset(-20);
    }];

    NSScrollView *scrollView = [NSScrollView new];
    [self.view addSubview:scrollView];
    [scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    scrollView.backgroundColor = theme.backgroundColor;
    scrollView.hasVerticalScroller = YES;
    scrollView.hasHorizontalScroller = NO;
    scrollView.documentView = contentView;
    [self layout];
    [scrollView.documentView scrollPoint:NSMakePoint(0, NSHeight(contentView.bounds))];
}

- (void)layout {
    [super layout];
    NSRect bounds = self.bounds;
    bounds.size.width = MAX(50, NSWidth(bounds));
    bounds.size.height = self.contentView.fittingSize.height;
    self.contentView.frame = bounds;
}

#pragma mark - Private Methods
- (NSDictionary *)loadPlist:(NSURL *)url {
    NSDictionary *result = nil;
    NSData *data = [NSData dataFromNoCacheURL:url];
    if (data.length > 0) {
        NSError *error = nil;
        NSDictionary *plist = [NSPropertyListSerialization propertyListWithData:data options:0 format:nil error:&error];
        if (error == nil) {
            result = plist;
        }
    }
    return result;
}


@end
