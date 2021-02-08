//
//  CHWebViewController.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHWebViewController.h"
#import <WebKit/WebKit.h>
#import <Masonry/Masonry.h>
#import "CHWebViewRefresher.h"
#import "CHTheme.h"

@interface CHWebViewController () <WKNavigationDelegate>

@property (nonatomic, readonly, strong) WKWebView *webView;
@property (nonatomic, readonly, strong) UIProgressView *progressView;
@property (nonatomic, readonly, strong) CHWebViewRefresher * refresher;
@property (nonatomic, nullable, strong) NSString *defaultTitle;
@property (nonatomic, nullable, strong) UIView *emptyView;
@property (nonatomic, readonly, strong) NSURL *url;

@end

@implementation CHWebViewController

- (instancetype)initWithUrl:(NSURL *)url parameters:(nullable NSDictionary<NSString *, id> *)params {
    if (self = [super init]) {
        _url = url;
        _defaultTitle = [params valueForKey:@"title"];
        self.title = self.defaultTitle;
    }
    return self;
}

- (void)dealloc {
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
    [self.webView removeObserver:self forKeyPath:@"title"];
    [self.webView removeObserver:self forKeyPath:@"URL"];
    [self.webView removeObserver:self forKeyPath:@"hasOnlySecureContent"];
    self.webView.navigationDelegate = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CHWebViewRefresher *refreshControl = [CHWebViewRefresher new];
    [refreshControl addTarget:self action:@selector(actionRefresh:) forControlEvents:UIControlEventValueChanged];

    WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:[WKWebViewConfiguration new]];
    [self.view addSubview:(_webView = webView)];
    [webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    [webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
    [webView addObserver:self forKeyPath:@"URL" options:NSKeyValueObservingOptionNew context:nil];
    [webView addObserver:self forKeyPath:@"hasOnlySecureContent" options:NSKeyValueObservingOptionNew context:nil];
    webView.scrollView.refreshControl = (_refresher = refreshControl);
    webView.backgroundColor = CHTheme.shared.backgroundColor;
    webView.allowsBackForwardNavigationGestures = YES;
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
    
    [webView loadRequest:[NSURLRequest requestWithURL:self.url]];
}

#pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    [self showEmpty:NO];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if (webView.alpha < 1.0) {
        [UIViewPropertyAnimator runningPropertyAnimatorWithDuration:kCHAnimateMediumDuration delay:0 options:0 animations:^{
            webView.alpha = 1;
        } completion:nil];
    }
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    [self showEmpty:YES];
}

#pragma mark - Observe Methods
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.webView) {
        if ([keyPath isEqualToString:@"title"]) {
            NSString *title = self.webView.title;
            if (self.defaultTitle.length > 0 && !self.webView.canGoBack) {
                title = self.defaultTitle;
            }
            [UIViewPropertyAnimator runningPropertyAnimatorWithDuration:kCHAnimateMediumDuration delay:0 options:0 animations:^{
                self.title = title;
            } completion:nil];
            return;
        } else if ([keyPath isEqualToString:@"estimatedProgress"]) {
            CGFloat progress = self.webView.estimatedProgress;
            if (progress < 1.0) {
                [self.progressView setProgress:progress animated:YES];
            } else {
                [self.progressView setProgress:1.0 animated:NO];
                [UIViewPropertyAnimator runningPropertyAnimatorWithDuration:kCHAnimateSlowDuration delay:kCHAnimateSlowDuration options:0 animations:^{
                    self.progressView.alpha = 0;
                } completion:^(UIViewAnimatingPosition finalPosition) {
                    self.progressView.alpha = 1;
                    self.progressView.progress = 0;
                }];
            }
            return;
        } else if ([keyPath isEqualToString:@"URL"]) {
            NSString *host = self.webView.URL.host;
            if ([host hasPrefix:@"www."]) {
                host = [host substringFromIndex:@"www.".length];
            }
            self.refresher.host = host;
            return;
        } else if ([keyPath isEqualToString:@"hasOnlySecureContent"]) {
            self.refresher.hasOnlySecureContent = self.webView.hasOnlySecureContent;
            return;
        }
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark - Action Methods
- (void)actionRefresh:(UIRefreshControl *)refresher {
    [refresher endRefreshing];
    [self.webView reload];
}

- (void)actionReload:(id)sender {
    if (self.webView.URL != nil) {
        [self.webView reloadFromOrigin];
    } else {
        [self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];
    }
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
            tapLabel.font = [UIFont systemFontOfSize:16];
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


@end
