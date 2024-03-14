//
//  CHUserInfoViewController.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHUserInfoViewController.h"
#import <Masonry/Masonry.h>
#import "CHPasteboard.h"
#import "CHQrCodeView.h"
#import "CHRouter.h"
#import "CHLogic.h"
#import "CHTheme.h"

@interface CHUserInfoViewController ()

@property (nonatomic, readonly, strong) UILabel *accountLabel;
@property (nonatomic, readonly, strong) NSString *url;
@property (nonatomic, readonly, assign) BOOL autoClose;

@end

@implementation CHUserInfoViewController

- (instancetype)initWithParameters:(NSDictionary *)params {
    if (self = [super init]) {
        _autoClose = [[params valueForKey:@"auto-close"] boolValue];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    CHUserModel *user = CHLogic.shared.me;

    _url = [NSString stringWithFormat:@"chanify://offline/user?key=%@", user.key.seckey.base64Code];

    self.title = @"Backup Account".localized;

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"square.and.arrow.up"] style:UIBarButtonItemStylePlain target:self action:@selector(actionExport:)];

    CHTheme *theme = CHTheme.shared;

    UIScrollView *contentView = [UIScrollView new];
    [self.view addSubview:contentView];
    contentView.alwaysBounceVertical = YES;
    contentView.showsVerticalScrollIndicator = NO;
    contentView.showsHorizontalScrollIndicator = NO;
    contentView.backgroundColor = theme.backgroundColor;
    [contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.left.right.bottom.equalTo(self.view);
    }];

    CGSize size = UIScreen.mainScreen.bounds.size;
    size.width = MIN(MAX(MIN(size.width, size.height) - 60, 300), 600);
    size.height = size.width;
    
    CHQrCodeView *qrCodeView = [CHQrCodeView new];
    [contentView addSubview:qrCodeView];
    qrCodeView.url = self.url;
    [qrCodeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(contentView).offset(80);
        make.centerX.equalTo(contentView);
        make.size.mas_equalTo(size);
    }];
    
    UILabel *accountLabel = [UILabel new];
    [contentView addSubview:(_accountLabel = accountLabel)];
    accountLabel.textColor = theme.labelColor;
    accountLabel.font = [UIFont fontWithName:@kCHCodeFontName size:14];
    accountLabel.text = user.uid;
    [accountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(qrCodeView.mas_top).offset(-30);
        make.centerX.equalTo(qrCodeView);
    }];

    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionCopyAccount:)];
    [accountLabel addGestureRecognizer:recognizer];
    accountLabel.userInteractionEnabled = YES;
    
    UILabel *titleLabel = [UILabel new];
    [contentView addSubview:titleLabel];
    titleLabel.textColor = theme.labelColor;
    titleLabel.font = [UIFont systemFontOfSize:20];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.text = @"UserInfoTitle".localized;
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(qrCodeView.mas_bottom).offset(30);
        make.left.right.equalTo(qrCodeView);
    }];
    
    UILabel *detailLabel = [UILabel new];
    [contentView addSubview:detailLabel];
    detailLabel.numberOfLines = 0;
    NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
    style.alignment = NSTextAlignmentCenter;
    style.lineSpacing = 8;
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:@"UserInfoDetail".localized];
    [text addAttributes:@{
        NSFontAttributeName: theme.textFont,
        NSForegroundColorAttributeName: theme.labelColor,
        NSParagraphStyleAttributeName:style,
    } range:NSMakeRange(0, text.length)];
    detailLabel.attributedText = text;
    [detailLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(titleLabel.mas_bottom).offset(16);
        make.left.right.equalTo(titleLabel);
    }];

}

#pragma mark - Action Methods
- (void)actionExport:(UIBarButtonItem *)sender {
    @weakify(self);
    [CHRouter.shared showShareItem:@[self.view.snapshotImage, [NSURL URLWithString:self.url]] sender:sender handler:^(BOOL completed, NSError *error) {
        if (error != nil) {
            [CHRouter.shared makeToast:@"Export failed".localized];
        } else if (completed) {
            [CHRouter.shared makeToast:@"Export success".localized];
            @strongify(self);
            if (self.autoClose) {
                [self closeAnimated:YES completion:nil];
            }
        }
    }];
}

- (void)actionCopyAccount:(UILongPressGestureRecognizer *)recognizer {
    [CHPasteboard.shared copyWithName:@"Account".localized value:self.accountLabel.text];
}


@end
