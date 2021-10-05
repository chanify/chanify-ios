//
//  CHBlockTokenViewPage.m
//  OSX
//
//  Created by WizJin on 2021/10/4.
//

#import "CHBlockTokenViewPage.h"
#import <Masonry/Masonry.h>
#import "CHPasteboard.h"
#import "CHToken.h"
#import "CHLogic.h"
#import "CHTheme.h"

@interface CHBlockTokenViewPage () <NSTextViewDelegate>

@property (nonatomic, readonly, strong) NSTextView *tokenView;
@property (nonatomic, readonly, strong) CHLabel *warnLabel;
@property (nonatomic, readonly, strong) NSButton *pasteButton;

@end

@implementation CHBlockTokenViewPage

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Add Token To Blocklist".localized;
    
    CHTheme *theme = CHTheme.shared;
    
    self.rightBarButtonItem = [CHBarButtonItem itemDoneWithTarget:self action:@selector(actionDone:)];
    self.rightBarButtonItem.enabled = NO;
    self.view.backgroundColor = theme.groupedBackgroundColor;

    NSScrollView *scrollView = [NSTextView scrollablePlainDocumentContentTextView];
    [self.view addSubview:scrollView];
    scrollView.wantsLayer = YES;
    scrollView.layer.cornerRadius = 4;
    [scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(14);
        make.left.equalTo(self.view).offset(16);
        make.right.equalTo(self.view).offset(-16);
        make.height.mas_equalTo(160);
    }];

    NSTextView *tokenView = (NSTextView *)scrollView.documentView;
    _tokenView = tokenView;
    tokenView.backgroundColor = theme.cellBackgroundColor;
    tokenView.font = [CHFont monospacedSystemFontOfSize:16 weight:UIFontWeightRegular];
    tokenView.delegate = self;

    CHLabel *warnLabel = [CHLabel new];
    [self.view addSubview:(_warnLabel = warnLabel)];
    [warnLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(scrollView.mas_bottom).offset(10);
        make.left.equalTo(scrollView);
    }];
    warnLabel.font = theme.detailFont;
    warnLabel.textColor = theme.alertColor;
    warnLabel.text = @"Invalid token".localized;
    warnLabel.alpha = 0;
    
    NSButton *pasteButton = [NSButton buttonWithTitle:@"Copy token from pasteboard".localized target:self action:@selector(actionPaste:)];
    [self.view addSubview:(_pasteButton = pasteButton)];
    [pasteButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(tokenView.mas_bottom).offset(6);
        make.right.equalTo(tokenView);
    }];
    pasteButton.bezelStyle = NSBezelStyleInline;
}

- (NSSize)calcContentSize {
    return NSMakeSize(400, 500);
}

#pragma mark - NSTextViewDelegate
- (void)textDidChange:(NSNotification *)notification {
    [self tokenDidChange];
}

#pragma mark - Action Methods
- (void)actionPaste:(id)sender {
    NSString *value = CHPasteboard.shared.stringValue ?: @"";
    if (![value isEqualToString:self.tokenView.string]) {
        self.tokenView.string = value;
        [self tokenDidChange];
    }
}

- (void)actionDone:(id)sender {
    [CHLogic.shared upsertBlockedToken:[self.tokenView.string stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet]];
    [self closeAnimated:YES completion:nil];
}

#pragma mark - Private Methods
- (void)tokenDidChange {
    BOOL res = NO;
    NSString *value = [self.tokenView.string stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (value.length > 0) {
        if ([CHToken tokenWithString:value] != nil) {
            res = YES;
        }
    }
    self.warnLabel.alpha = ((res || value.length == 0) ? 0 : 1);
    self.rightBarButtonItem.enabled = res;
}


@end
