//
//  CHLoginViewController.m
//  OSX
//
//  Created by WizJin on 2021/8/31.
//

#import "CHLoginViewController.h"
#import <Masonry/Masonry.h>
#import "CHLoginQrCodeView.h"
#import "CHLoginAccountView.h"
#import "CHRouter.h"
#import "CHLogic.h"
#import "CHTheme.h"

@interface CHLoginViewController () <CHLoginQrCodeViewDelegate, CHLoginAccountViewDelegate>

@property (nonatomic, readonly, strong) CHLoginQrCodeView *loginQrCodeView;
@property (nonatomic, readonly, strong) CHLoginAccountView *loginAccountView;

@end

@implementation CHLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CHTheme *theme = CHTheme.shared;
    
    NSButton *button = [NSButton button];
    button.target = self;
    button.action = @selector(actionChangeLoginMode:);
    button.titleFont = theme.mediumFont;
    button.titleTintColor = theme.tintColor;
    [self.view addSubview:button];
    [button mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-12);
    }];
    
    CHLoginQrCodeView *loginQrCodeView = [CHLoginQrCodeView new];
    [self.view addSubview:(_loginQrCodeView = loginQrCodeView)];
    [loginQrCodeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.bottom.equalTo(button.mas_top).offset(-8);
    }];
    loginQrCodeView.delegate = self;
    
    CHLoginAccountView *loginAccountView = [CHLoginAccountView new];
    [self.view addSubview:(_loginAccountView = loginAccountView)];
    [loginAccountView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(loginQrCodeView);
    }];
    loginAccountView.hidden = YES;
    loginAccountView.delegate = self;
    
    [self updateUIStatus:button];
}

#pragma mark - CHLoginViewDelegate
- (void)loginWithQrCode:(NSURL *)url {
    [self loginWithURL:url view:self.loginQrCodeView];
}

#pragma mark - CHLoginAccountViewDelegate
- (void)loginWithAccount:(NSString *)account {
    if (![account.lowercaseString hasPrefix:@"chanify://"]) {
        account = [@"chanify://offline/user?key=" stringByAppendingString:account];
    }
    [self loginWithURL:[NSURL URLWithString:account] view:self.loginAccountView];
}

#pragma mark - Action Methods
- (void)actionChangeLoginMode:(NSButton *)button {
    self.loginQrCodeView.hidden = !self.loginQrCodeView.hidden;
    self.loginAccountView.hidden = !self.loginQrCodeView.hidden;
    [self updateUIStatus:button];
}

#pragma mark - Private Methods
- (void)updateUIStatus:(NSButton *)button {
    if (self.loginQrCodeView.hidden) {
        button.title = @"Login with QrCode".localized;
    } else {
        button.title = @"Login with Account".localized;
    }
}

- (void)loginWithURL:(NSURL *)url view:(id<CHLoginViewItem>)view {
    if (url == nil || ![url.scheme isEqual: @"chanify"] || ![url.host isEqual: @"offline"] || ![url.path isEqual: @"/user"]) {
        [view setStatusText:@"Import account failed!".localized];
    } else {
        [view setShowIndicator:YES];
        NSString *key = @"";
        NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
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
                [view setStatusText:@"Import account failed!".localized];
                [CHRouter.shared makeToast:@"Import account failed".localized];
            }
            [view setShowIndicator:NO];
        }];
    }
}


@end
