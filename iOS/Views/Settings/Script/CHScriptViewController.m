//
//  CHScriptViewController.m
//  iOS
//
//  Created by WizJin on 2022/4/23.
//

#import "CHScriptViewController.h"
#import <WebKit/WebKit.h>
#import <Masonry/Masonry.h>
#import "CHUserDataSource.h"
#import "CHScriptModel.h"
#import "CHRouter.h"
#import "CHLogic.h"
#import "CHTheme.h"

@interface CHScriptViewController () <WKNavigationDelegate>

@property (nonatomic, nullable, strong) CHScriptModel *model;
@property (nonatomic, nullable, strong) NSString *scriptName;
@property (nonatomic, nullable, strong) NSString *scriptContent;
@property (nonatomic, readonly, strong) WKWebView *webView;

@end

@implementation CHScriptViewController

- (instancetype)initWithParameters:(NSDictionary *)params {
    if (self = [super init]) {
        _model = [CHLogic.shared.userDataSource scriptWithName:[params valueForKey:@"name"]];
    }
    return self;
}

- (instancetype)initWithName:(NSString *)name script:(nullable NSString *)script {
    if (self = [super init]) {
        _model = nil;
        _scriptName = name;
        _scriptContent = script;
    }
    return self;
}

- (void)dealloc {
    self.webView.navigationDelegate = nil;
    [self.webView stopLoading];
    if (self.delegate != nil) {
        [self.delegate scriptViewController:self script:self.scriptCode];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = CHTheme.shared.backgroundColor;

    WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
    WKUserContentController *userContentController = configuration.userContentController;
    WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
    [self.view addSubview:(_webView = webView)];
    webView.scrollView.showsHorizontalScrollIndicator = NO;
    webView.backgroundColor = self.view.backgroundColor;
    webView.navigationDelegate = self;
    webView.alpha = 0;
    [webView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.left.right.bottom.equalTo(self.view);
    }];

    NSString *scriptCode = nil;
    if (self.model == nil) {
        self.title = self.scriptName ?: @"";
        scriptCode = self.scriptContent;
    } else {
        self.title = self.model.name;
        scriptCode = [CHLogic.shared.userDataSource scriptContentWithName:self.model.name];
        CHBarButtonItem *rightBarButtonItem = [CHBarButtonItem itemDoneWithTarget:self action:@selector(actionDone:)];
        self.navigationItem.rightBarButtonItem = rightBarButtonItem;
    }
    
    if (self.title.length <= 0) {
        self.title = @"Script".localized;
    }

    NSString *encodeString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:@[scriptCode?:@""] options:0 error:nil] encoding:NSUTF8StringEncoding];
    scriptCode = [encodeString substringWithRange:NSMakeRange(2, encodeString.length - 4)];
    [userContentController addUserScript:[[WKUserScript alloc] initWithSource:[NSString stringWithFormat:@"window.scriptCode=\"%@\";", scriptCode] injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES]];
    NSURL *url = [NSBundle.mainBundle URLForResource:@"index" withExtension:@"html" subdirectory:@"editor"];
    [webView loadFileURL:url allowingReadAccessToURL:url.URLByDeletingLastPathComponent];
}

#pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if (webView.alpha < 1.0) {
        @weakify(self);
        [UIViewPropertyAnimator runningPropertyAnimatorWithDuration:kCHAnimateMediumDuration delay:0 options:0 animations:^{
            @strongify(self);
            self.webView.alpha = 1;
        } completion:nil];
    }
}

#pragma mark - Action Methods
- (void)actionDone:(id)sender {
    if (self.model != nil) {
        if ([CHLogic.shared updateScript:self.model.name content:self.scriptCode]) {
            [self closeAnimated:YES completion:nil];
        } else {
            [CHRouter.shared makeToast:@"Save script failed".localized];
        }
    }
}

#pragma mark - Private Methods
- (NSString *)scriptCode {
    __block BOOL finished = NO;
    __block NSString *code = nil;
    [self.webView evaluateJavaScript:@"document.querySelector('.editor').textContent" completionHandler:^(id value, NSError *error) {
        if (error == nil && [value isKindOfClass:NSString.class]) {
            code = value;
        }
        finished = YES;
    }];
    while (!finished) {
        [NSRunLoop.currentRunLoop runMode:NSDefaultRunLoopMode beforeDate:NSDate.distantFuture];
    }
    return code ?: @"";
}


@end
