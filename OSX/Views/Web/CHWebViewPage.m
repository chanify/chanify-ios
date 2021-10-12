//
//  CHWebViewPage.m
//  OSX
//
//  Created by WizJin on 2021/10/9.
//

#import "CHWebViewPage.h"
#import <WebKit/WebKit.h>
#import <Masonry/Masonry.h>
#import "CHTheme.h"

@interface CHWebViewPage () <WKNavigationDelegate>

@property (nonatomic, readonly, strong) NSURL *url;
@property (nonatomic, nullable, strong) NSString *defaultTitle;
@property (nonatomic, readonly, strong) WKWebView *webView;

@end

@implementation CHWebViewPage

- (instancetype)initWithParameters:(NSDictionary *)params {
    if (self = [super init]) {
        _url = [params valueForKey:@"url"];
        _defaultTitle = [params valueForKey:@"title"] ?: @"";
        self.title = self.defaultTitle;
    }
    return self;
}

- (void)dealloc {
    self.webView.navigationDelegate = nil;
    [self.webView stopLoading];
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
    [self.webView removeObserver:self forKeyPath:@"title"];
    [self.webView removeObserver:self forKeyPath:@"canGoBack"];
}

- (BOOL)isEqualWithParameters:(NSDictionary *)params {
    return [self.url isEqualTo:[params valueForKey:@"url"]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CHTheme *theme = CHTheme.shared;
    self.view.backgroundColor = theme.backgroundColor;

    WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:[WKWebViewConfiguration new]];
    [self.view addSubview:(_webView = webView)];
    [webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    [webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
    [webView addObserver:self forKeyPath:@"canGoBack" options:NSKeyValueObservingOptionNew context:nil];
    webView.backgroundColor = theme.backgroundColor;
    webView.navigationDelegate = self;
    [webView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    webView.alpha = 0;
    
    [webView loadRequest:[NSURLRequest requestWithURL:self.url]];
}

#pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        NSURL *url = navigationAction.request.URL;
        if (url != nil) {
            if (canOpenURL(url, self.url)) {
                [NSWorkspace.sharedWorkspace openURL:url];
                decisionHandler(WKNavigationActionPolicyCancel);
                return;
//                if ([UIApplication.sharedApplication canOpenURL:url]) {
//                    [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
//                    decisionHandler(WKNavigationActionPolicyCancel);
//                    return;
//                }
            }
        }
        if (navigationAction.targetFrame == nil) {
            [webView loadRequest:navigationAction.request];
        }
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    //[self showEmpty:NO];
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
    BOOL appOpen = NO;
    NSURL *url = nil;
    NSString *failedURL = [error.userInfo valueForKey:NSURLErrorFailingURLStringErrorKey];
    if (failedURL.length > 0) {
        url = [NSURL URLWithString:failedURL];
    }
    switch (error.code) {
        case 0:
            appOpen = YES;
            break;
        default:
            appOpen = canOpenURL(url, self.url);
            break;
    }
    if (appOpen && url != nil) {
        [NSWorkspace.sharedWorkspace openURL:url];
        return;
    }
    //[self showEmpty:YES];
}

- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler {
    NSURLCredential *credential = challenge.proposedCredential;
    if (credential != nil && challenge.previousFailureCount > 0) {
        credential = nil;
    }
    if (credential == nil) {
        NSString *authenticationMethod = challenge.protectionSpace.authenticationMethod;
        if ([authenticationMethod isEqualToString:NSURLAuthenticationMethodDefault]
            || [authenticationMethod isEqualToString:NSURLAuthenticationMethodHTTPBasic]
            || [authenticationMethod isEqualToString:NSURLAuthenticationMethodHTTPDigest]) {
            if (challenge.previousFailureCount == 0) {
                [self authenticationWithHTTPBasic:^(NSURLCredential * _Nullable credential) {
                    if (credential != nil) {
                        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
                    } else {
                        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
                    }
                }];
                return;
            }
        } else if ([authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
            if (challenge.previousFailureCount == 0) {
                credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            }
        }
    }
    if (credential != nil) {
        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
    } else {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}


#pragma mark - Observe Methods
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.webView) {
        if ([keyPath isEqualToString:@"title"]) {
            NSString *title = self.webView.title;
            if (self.defaultTitle.length > 0 && !self.webView.canGoBack) {
                title = self.defaultTitle;
            }
            @weakify(self);
            [UIViewPropertyAnimator runningPropertyAnimatorWithDuration:kCHAnimateMediumDuration delay:0 options:0 animations:^{
                @strongify(self);
                self.title = title;
            } completion:nil];
            return;
        } else if ([keyPath isEqualToString:@"estimatedProgress"]) {
            return;
        } else if ([keyPath isEqualToString:@"canBack"]) {
            return;
        }
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark - Private Methods
- (void)authenticationWithHTTPBasic:(void (^)(NSURLCredential * _Nullable credential))completionHandler {
    // TODO: fix http basic
    completionHandler(nil);
}

static inline BOOL canOpenURL(NSURL *url, NSURL *refrenceURL) {
    BOOL appOpen = NO;
    NSString *scheme = url.scheme.lowercaseString;
    if ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]) {
        NSString *host = url.host.lowercaseString;
        appOpen = [host isEqualToString:@"itunes.apple.com"];
    } else {
        if (![scheme isEqualToString:@"chanify"]) {
            appOpen = YES;
        } else if (refrenceURL != nil) {
            NSString *host = refrenceURL.host.lowercaseString;
            if ([host isEqualToString:@"chanify.net"] || [host isEqualToString:@"www.chanify.net"]) {
                appOpen = YES;
            }
        }
    }
    return appOpen;
}


@end
