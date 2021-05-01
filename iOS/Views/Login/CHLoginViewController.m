//
//  CHLoginViewController.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHLoginViewController.h"
#import <Masonry/Masonry.h>
#import "CHScanViewController.h"
#import "CHLogic+iOS.h"
#import "CHRouter.h"
#import "CHTheme.h"

@interface CHLoginViewController () <CHScanViewControllerDelegate>

@property (nonatomic, readonly, strong) UIScrollView *contentView;
@property (nonatomic, readonly, strong) UIButton *createButton;
@property (nonatomic, readonly, strong) UIButton *importButton;

@end

@implementation CHLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CHTheme *theme = CHTheme.shared;
    
    UIScrollView *contentView = [UIScrollView new];
    [self.view addSubview:(_contentView = contentView)];
    contentView.alwaysBounceVertical = YES;
    contentView.showsVerticalScrollIndicator = NO;
    contentView.showsHorizontalScrollIndicator = NO;
    [contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.height.greaterThanOrEqualTo(self.view);
    }];

    UIImageView *logoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Channel"]];
    [contentView addSubview:logoView];
    logoView.tintColor = theme.labelColor;
    [logoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(contentView).offset(140);
        make.centerX.equalTo(self.view);
        make.size.mas_equalTo(CGSizeMake(64, 64));
    }];

    UIButton *createButton = [UIButton new];
    [contentView addSubview:(_createButton = createButton)];
    UIColor *buttonColor = theme.backgroundColor;
    [createButton addTarget:self action:@selector(actionCreateAccount:) forControlEvents:UIControlEventTouchUpInside];
    [createButton setTitleColor:buttonColor forState:UIControlStateNormal];
    [createButton setTitleColor:[buttonColor colorWithAlphaComponent:0.6] forState:UIControlStateHighlighted];
    [createButton setTitleColor:[buttonColor colorWithAlphaComponent:0.3] forState:UIControlStateDisabled];
    [createButton setTitle:@"Create new account".localized forState:UIControlStateNormal];
    createButton.titleLabel.font = [UIFont boldSystemFontOfSize:17.5];
    createButton.backgroundColor = theme.labelColor;
    createButton.layer.cornerRadius = 21;
    [createButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(contentView);
        make.top.equalTo(logoView.mas_bottom).offset(140);
        make.size.mas_equalTo(CGSizeMake(240, createButton.layer.cornerRadius*2));
    }];

    UIButton *importButton = [UIButton new];
    [contentView addSubview:(_importButton = importButton)];
    [importButton addTarget:self action:@selector(actionImportAccount:) forControlEvents:UIControlEventTouchUpInside];
    [importButton setTitleColor:[createButton titleColorForState:UIControlStateNormal] forState:UIControlStateNormal];
    [importButton setTitleColor:[createButton titleColorForState:UIControlStateHighlighted] forState:UIControlStateHighlighted];
    [importButton setTitleColor:[createButton titleColorForState:UIControlStateDisabled] forState:UIControlStateDisabled];
    [importButton setTitle:@"Import old account".localized forState:UIControlStateNormal];
    importButton.titleLabel.font = createButton.titleLabel.font;
    importButton.backgroundColor = createButton.backgroundColor;
    importButton.layer.cornerRadius = createButton.layer.cornerRadius;
    [importButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(createButton.mas_bottom).offset(20);
        make.centerX.equalTo(createButton);
        make.size.equalTo(createButton);
    }];
    
    UIButton *privacyTipsLabel = [UIButton new];
    [contentView addSubview:privacyTipsLabel];
    [privacyTipsLabel addTarget:self action:@selector(actionGotoPrivacy:) forControlEvents:UIControlEventTouchUpInside];
    [privacyTipsLabel setTitle:@"Privacy Policy".localized forState:UIControlStateNormal];
    [privacyTipsLabel setTitleColor:theme.minorLabelColor forState:UIControlStateNormal];
    privacyTipsLabel.titleLabel.font = [UIFont systemFontOfSize:12];
    [privacyTipsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(30);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-30);
    }];
}

#pragma mark - CHScanViewControllerDelegate
- (void)scanFindURL:(NSURL *)url {
    if (![url.scheme isEqual: @"chanify"] || ![url.host isEqual: @"offline"] || ![url.path isEqual: @"/user"]) {
        [CHRouter.shared makeToast:@"Import account failed".localized];
    } else {
        self.importButton.enabled = NO;
        @weakify(self);
        [CHRouter.shared showIndicator:YES];
        NSString *key = @"";
        NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:nil];
        for (NSURLQueryItem *item in components.queryItems) {
            if ([item.name isEqual:@"key"]) {
                key = item.value;
                break;
            }
        }
        [CHLogic.shared importAccount:key completion:^(CHLCode result) {
            if (result == CHLCodeOK) {
                [CHRouter.shared routeTo:@"/page/main"];
            } else {
                [CHRouter.shared makeToast:@"Import account failed".localized];
            }
            [CHRouter.shared showIndicator:NO];
            @strongify(self);
            self.importButton.enabled = YES;
        }];
    }
}

#pragma mark - Action Methods
- (void)actionGotoPrivacy:(id)sender {
    [CHRouter.shared routeTo:@"/page/privacy" withParams:@{ @"noauth": @YES }];
}

- (void)actionCreateAccount:(UIButton *)button {
    button.enabled = NO;
    [CHRouter.shared showIndicator:YES];
    [CHLogic.shared createAccountWithCompletion:^(CHLCode result) {
        [CHRouter.shared showIndicator:NO];
        if (result == CHLCodeOK) {
            [CHRouter.shared routeTo:@"/page/main"];
            dispatch_main_after(kCHAnimateSlowDuration, ^{
                [CHRouter.shared routeTo:@"/page/user-info" withParams:@{ @"show": @"present", @"auto-close": @YES }];
            });
        } else {
            [CHRouter.shared makeToast:@"Create account failed".localized];
        }
        button.enabled = YES;
    }];
}

- (void)actionImportAccount:(id)sender {
    CHScanViewController *scan = [CHScanViewController new];
    scan.delegate = self;
    [CHRouter.shared presentViewController:scan animated:YES];
}


@end
