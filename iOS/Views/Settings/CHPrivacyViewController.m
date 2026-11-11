//
//  CHPrivacyViewController.m
//  Chanify
//
//  Created by WizJin on 2021/2/21.
//

#import "CHPrivacyViewController.h"
#import <WebKit/WebKit.h>
#import <Masonry/Masonry.h>
#import "CHTheme.h"

@interface CHPrivacyViewController () <WKNavigationDelegate>

@property (nonatomic, readonly, strong) WKWebView *webView;
@property (nonatomic, readonly, strong) UIProgressView *progressView;
@property (nonatomic, nullable, strong) UIView *emptyView;
@property (nonatomic, readonly, strong) NSURL *url;
@property (nonatomic, assign) BOOL showingOfflinePolicy;

@end

@implementation CHPrivacyViewController

- (void)dealloc {
    self.webView.navigationDelegate = nil;
    [self.webView stopLoading];
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _url = [NSURL URLWithString:@kCHPrivacyURL];

    self.title = @"Privacy Policy".localized;

    WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:[WKWebViewConfiguration new]];
    [self.view addSubview:(_webView = webView)];
    [webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    webView.backgroundColor = CHTheme.shared.backgroundColor;
    webView.navigationDelegate = self;
    webView.alpha = 0;
    [webView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.left.right.bottom.equalTo(self.view);
    }];
    
    UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    [self.view addSubview:(_progressView = progressView)];
    progressView.progress = 0;
    [progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(1);
    }];
    
    [webView loadRequest:[NSURLRequest requestWithURL:self.url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:15]];
}

#pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (navigationAction.targetFrame.mainFrame) {
        self.showingOfflinePolicy = navigationAction.request.URL.isFileURL;
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    [self showEmpty:NO];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if (webView.alpha < 1.0) {
        @weakify(self);
        [UIViewPropertyAnimator runningPropertyAnimatorWithDuration:kCHAnimateMediumDuration delay:0 options:0 animations:^{
            @strongify(self);
            self.webView.alpha = 1;
        } completion:nil];
    }
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    if (error.code != NSURLErrorCancelled) [self showOfflinePolicy];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if (error.code != NSURLErrorCancelled) [self showOfflinePolicy];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    NSURLResponse *response = navigationResponse.response;
    if (navigationResponse.forMainFrame && [response isKindOfClass:NSHTTPURLResponse.class] && [(NSHTTPURLResponse *)response statusCode] >= 400) {
        decisionHandler(WKNavigationResponsePolicyCancel);
        [self showOfflinePolicy];
        return;
    }
    decisionHandler(WKNavigationResponsePolicyAllow);
}

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
    [self showOfflinePolicy];
}

#pragma mark - Observe Methods
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.webView && [keyPath isEqualToString:@"estimatedProgress"]) {
        CGFloat progress = self.webView.estimatedProgress;
        if (progress < 1.0) {
            [self.progressView setProgress:progress animated:YES];
        } else {
            [self.progressView setProgress:1.0 animated:NO];
            @weakify(self);
            [UIViewPropertyAnimator runningPropertyAnimatorWithDuration:kCHAnimateSlowDuration delay:kCHAnimateSlowDuration options:0 animations:^{
                @strongify(self);
                self.progressView.alpha = 0;
            } completion:^(UIViewAnimatingPosition finalPosition) {
                @strongify(self);
                self.progressView.alpha = 1;
                self.progressView.progress = 0;
            }];
        }
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark - Private Methods
- (void)showOfflinePolicy {
    if (self.showingOfflinePolicy) {
        [self showEmpty:YES];
        return;
    }
    NSURL *url = [NSBundle.mainBundle URLForResource:@"Privacy" withExtension:@"html" subdirectory:@"Settings.bundle"];
    if (url == nil) {
        [self showEmpty:YES];
        return;
    }
    self.showingOfflinePolicy = YES;
    [self.webView loadFileURL:url allowingReadAccessToURL:url];
}

- (void)showEmpty:(BOOL)show {
    if (!show) {
        if (self.emptyView != nil) {
            [self.emptyView removeFromSuperview];
            self.emptyView = nil;
        }
    } else {
        if (self.emptyView == nil) {
            CHTheme *theme = CHTheme.shared;
            UIScrollView *emptyView = [UIScrollView new];
            [self.view addSubview:(self.emptyView = emptyView)];
            [emptyView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.edges.equalTo(self.view);
            }];

            emptyView.alwaysBounceVertical = YES;
            emptyView.backgroundColor = theme.groupedBackgroundColor;
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"bolt.slash"]];
            [emptyView addSubview:imageView];
            imageView.tintColor = theme.minorLabelColor;
            imageView.contentMode = UIViewContentModeScaleAspectFill;
            [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.centerY.equalTo(emptyView).offset(-200);
                make.centerX.equalTo(emptyView);
                make.height.mas_equalTo(80);
            }];

            UILabel *tapLabel = [UILabel new];
            [emptyView addSubview:tapLabel];
            tapLabel.font = theme.textFont;
            tapLabel.textColor = theme.minorLabelColor;
            tapLabel.text = @"Tap to reload".localized;
            [tapLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(imageView.mas_bottom).offset(50);
                make.centerX.equalTo(imageView);
            }];

            UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionReload:)];
            [emptyView addGestureRecognizer:tapGestureRecognizer];
        }
    }
}

- (void)actionReload:(id)sender {
    self.showingOfflinePolicy = NO;
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:15]];
}


@end
