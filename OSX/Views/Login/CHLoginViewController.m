//
//  CHLoginViewController.m
//  OSX
//
//  Created by WizJin on 2021/8/31.
//

#import "CHLoginViewController.h"
#import <Masonry/Masonry.h>
#import "CHLoginView.h"
#import "CHRouter.h"
#import "CHLogic.h"

@interface CHLoginViewController () <CHLoginViewDelegate>

@property (nonatomic, readonly, strong) CHLoginView *loginView;

@end

@implementation CHLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CHLoginView *loginView = [CHLoginView new];
    [self.view addSubview:(_loginView = loginView)];
    [loginView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    loginView.delegate = self;
}

#pragma mark - CHLoginViewDelegate
- (void)loginWithQrCode:(NSURL *)url {
    if (url == nil || ![url.scheme isEqual: @"chanify"] || ![url.host isEqual: @"offline"] || ![url.path isEqual: @"/user"]) {
        self.loginView.statusText = @"Import account failed!".localized;
    } else {
        @weakify(self);
        self.loginView.showIndicator = YES;
        NSString *key = @"";
        NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
        for (NSURLQueryItem *item in components.queryItems) {
            if ([item.name isEqual:@"key"]) {
                key = item.value;
                break;
            }
        }
        [CHLogic.shared importAccount:key completion:^(CHLCode result) {
            @strongify(self);
            if (result == CHLCodeOK) {
                [CHRouter.shared routeTo:@"/page/main"];
            } else {
                self.loginView.statusText = @"Import account failed!".localized;
                [CHRouter.shared makeToast:@"Import account failed".localized];
            }
            self.loginView.showIndicator = NO;
        }];
    }
}

@end
