//
//  CHLoginAccountView.m
//  OSX
//
//  Created by WizJin on 2022/3/23.
//

#import "CHLoginAccountView.h"
#import <Masonry/Masonry.h>
#import "CHIndicatorView.h"
#import "CHTheme.h"

@interface CHLoginAccountView () <NSTextFieldDelegate>

@property (nonatomic, readonly, assign) BOOL loading;
@property (nonatomic, readonly, strong) NSTextField *accountEdit;
@property (nonatomic, readonly, strong) CHLabel *statusLabel;
@property (nonatomic, readonly, strong) CHLabel *noteLabel;
@property (nonatomic, readonly, strong) CHIndicatorView *indicatorView;
@property (nonatomic, readonly, strong) NSButton *loginButton;

@end


@implementation CHLoginAccountView

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        [self registerForDraggedTypes:@[NSPasteboardTypeFileURL]];
        
        _loading = NO;
        
        CHTheme *theme = CHTheme.shared;
        
        CHLabel *titleLabel = [CHLabel new];
        [self addSubview:titleLabel];
        [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self);
            make.top.equalTo(self);
        }];
        titleLabel.font = [CHFont systemFontOfSize:18 weight:NSFontWeightBold];
        titleLabel.textColor = theme.labelColor;
        titleLabel.text = @"Login".localized;
        
        NSTextField *accountEdit = [NSTextField new];
        [self addSubview:(_accountEdit = accountEdit)];
        accountEdit.delegate = self;
        accountEdit.bezeled = NO;
        accountEdit.bordered = NO;
        accountEdit.maximumNumberOfLines = 1;
        accountEdit.focusRingType = NSFocusRingTypeNone;
        accountEdit.placeholderString = @"Please input account".localized;
        [accountEdit mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(10);
            make.right.equalTo(self).offset(-10);
            make.top.equalTo(titleLabel.mas_bottom).offset(50);
            make.height.mas_equalTo(50);
        }];
        
        NSButton *button = [NSButton new];
        button.bezelStyle = NSBezelStyleShadowlessSquare;
        button.target = self;
        button.action = @selector(actionLogin:);
        button.titleFont = theme.textFont;
        button.titleTintColor = theme.tintColor;
        button.title = @"Login".localized;
        [self addSubview:(_loginButton = button)];
        [button mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self);
            make.top.equalTo(accountEdit.mas_bottom).offset(50);
            make.size.mas_equalTo(NSMakeSize(200, 40));
        }];
        button.enabled = NO;

        CHLabel *statusLabel = [CHLabel new];
        [self addSubview:(_statusLabel = statusLabel)];
        [statusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self);
            make.bottom.equalTo(self).offset(-60);
        }];
        statusLabel.font = theme.textFont;
        statusLabel.textColor = theme.labelColor;
        
        CHLabel *noteLabel = [CHLabel new];
        [self addSubview:(_noteLabel = noteLabel)];
        [noteLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self);
            make.bottom.equalTo(self);
        }];
        noteLabel.font = theme.detailFont;
        noteLabel.textColor = theme.minorLabelColor;
        noteLabel.text = @"Get Account from Chanify app on your iPhone.".localized;
        
        CHIndicatorView *indicatorView = [CHIndicatorView new];
        [self addSubview:(_indicatorView = indicatorView)];
        [indicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self);
        }];
        indicatorView.tintColor = theme.labelColor;
        indicatorView.lineWidth = 2;
        indicatorView.radius = 36;
        indicatorView.speed = 1.8;
        indicatorView.gap = 0.8;
    }
    return self;
}

- (void)setStatusText:(NSString *)text {
    self.statusLabel.text = text;
}

- (void)setShowIndicator:(BOOL)bSHow {
    if (self.loading != bSHow) {
        _loading = bSHow;
        self.statusLabel.hidden = bSHow;
        self.noteLabel.hidden = bSHow;
        self.loginButton.hidden = bSHow;
        self.accountEdit.enabled = !bSHow;
        if (bSHow) {
            [self.indicatorView startAnimating];
        } else {
            [self.indicatorView stopAnimating:nil];
        }
    }
}

#pragma mark - NSTextFieldDelegate
- (void)controlTextDidChange:(NSNotification *)obj {
    self.loginButton.enabled = (self.accountText.length > 0);
}

#pragma mark - Action Methods
- (void)actionLogin:(id)sender {
    NSString *value = self.accountText;
    if (value.length > 0 && self.delegate != nil) {
        [self.delegate loginWithAccount:value];
    }
}

#pragma mark - Private Methods
- (NSString *)accountText {
    return [self.accountEdit.stringValue stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
}


@end
