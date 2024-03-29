//
//  CHBlockTokenViewController.m
//  iOS
//
//  Created by WizJin on 2021/6/4.
//

#import "CHBlockTokenViewController.h"
#import <Masonry/Masonry.h>
#import "CHPasteboard.h"
#import "CHLogic.h"
#import "CHToken.h"
#import "CHTheme.h"

@interface CHBlockTokenViewController () <UITextViewDelegate>

@property (nonatomic, readonly, strong) UITextView *tokenView;
@property (nonatomic, readonly, strong) UILabel *warnLabel;
@property (nonatomic, readonly, strong) UIButton *pasteButton;

@end

@implementation CHBlockTokenViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Add Token To Blocklist".localized;

    CHTheme *theme = CHTheme.shared;

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(actionDone:)];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    UIScrollView *view = [UIScrollView new];
    [self.view addSubview:view];
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.left.right.bottom.equalTo(self.view);
    }];
    view.alwaysBounceVertical = YES;
    view.backgroundColor = theme.groupedBackgroundColor;
    
    UITextView *tokenView = [UITextView new];
    [view addSubview:(_tokenView = tokenView)];
    [tokenView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(view).offset(14);
        make.left.equalTo(self.view).offset(16);
        make.right.equalTo(self.view).offset(-16);
        make.height.mas_equalTo(160);
    }];
    tokenView.backgroundColor = theme.cellBackgroundColor;
    tokenView.layer.cornerRadius = 4;
    tokenView.font = [UIFont monospacedSystemFontOfSize:16 weight:UIFontWeightRegular];
    tokenView.scrollEnabled = NO;
    tokenView.delegate = self;
    
    UILabel *warnLabel = [UILabel new];
    [view addSubview:(_warnLabel = warnLabel)];
    [warnLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(tokenView.mas_bottom).offset(10);
        make.left.equalTo(tokenView);
    }];
    warnLabel.font = theme.detailFont;
    warnLabel.textColor = theme.alertColor;
    warnLabel.text = @"Invalid token".localized;
    warnLabel.alpha = 0;
    
    UIButton *pasteButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [view addSubview:(_pasteButton = pasteButton)];
    [pasteButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(tokenView.mas_bottom).offset(6);
        make.right.equalTo(tokenView);
    }];
    [pasteButton setTitle:@"Copy token from pasteboard".localized forState:UIControlStateNormal];
    [pasteButton addTarget:self action:@selector(actionPaste:) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - UITextViewDelegate
- (void)textViewDidChange:(UITextView *)textView {
    BOOL res = NO;
    NSString *value = [textView.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (value.length > 0) {
        if ([CHToken tokenWithString:value] != nil) {
            res = YES;
        }
    }
    self.warnLabel.alpha = ((res || value.length == 0) ? 0 : 1);
    self.navigationItem.rightBarButtonItem.enabled = res;
}

#pragma mark - Action Methods
- (void)actionPaste:(id)sender {
    NSString *value = CHPasteboard.shared.stringValue ?: @"";
    if (![value isEqualToString:self.tokenView.text]) {
        self.tokenView.text = value;
        [self textViewDidChange:self.tokenView];
    }
}

- (void)actionDone:(id)sender {
    [CHLogic.shared upsertBlockedToken:[self.tokenView.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet]];
    [self closeAnimated:YES completion:nil];
}


@end
