//
//  CHWebViewRefresher.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHWebViewRefresher.h"
#import "CHTheme.h"

#define kRefreshButton      46
#define kRefreshLogoSize    24
#define kRefreshMaxHeight   160

@interface CHWebViewRefresher ()

@property (nonatomic, readonly, strong) UIImageView *secureIcon;
@property (nonatomic, readonly, strong) UILabel *hostLabel;
@property (nonatomic, readonly, strong) UILabel *tipsLabel;
@property (nonatomic, readonly, strong) UIImageView *refreshIcon;
@property (nonatomic, readonly, strong) UIView *refreshIconBG;
@property (nonatomic, readonly, assign) CGFloat activeOffset;

@end

@implementation CHWebViewRefresher

- (instancetype)init {
    if (self = [super init]) {
        _activeOffset = MAXFLOAT;

        CHTheme *theme = CHTheme.shared;
        
        self.backgroundColor = theme.backgroundColor;
        self.tintColor = UIColor.clearColor;

        UIImageView *secureIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"exclamationmark.triangle.fill"]];
        [self addSubview:(_secureIcon = secureIcon)];
        secureIcon.frame = CGRectMake(0, 0, 10, 10);
        secureIcon.contentMode = UIViewContentModeScaleAspectFit;
        secureIcon.tintColor = theme.warnColor;
        secureIcon.alpha = 0;

        UILabel *hostLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, 0, 16)];
        [self addSubview:(_hostLabel = hostLabel)];
        hostLabel.font = [UIFont boldSystemFontOfSize:12];
        hostLabel.textColor = theme.minorLabelColor;
        hostLabel.textAlignment = NSTextAlignmentCenter;
        hostLabel.numberOfLines = 1;
        hostLabel.alpha = 0;
        
        UILabel *tipsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 12)];
        [self addSubview:(_tipsLabel = tipsLabel)];
        tipsLabel.font = theme.smallFont;
        tipsLabel.textColor = theme.minorLabelColor;
        tipsLabel.textAlignment = NSTextAlignmentCenter;
        tipsLabel.numberOfLines = 1;
        tipsLabel.alpha = 0;
        tipsLabel.text = @"Release to reload".localized;

        UIView *refreshIconBG = [UIView new];
        [self addSubview:(_refreshIconBG = refreshIconBG)];
        refreshIconBG.backgroundColor = [theme.labelColor colorWithAlphaComponent:0.2];

        UIImageView *refreshIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Refresh"]];
        [self addSubview:(_refreshIcon = refreshIcon)];
        refreshIcon.tintColor = theme.labelColor;
        refreshIcon.alpha = 0;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat width = self.bounds.size.width;
    CGFloat height = -self.scrollView.contentOffset.y;
    CGFloat yoffset = 0;
    
    CGFloat iconWidth = self.secureIcon.bounds.size.width;
    
    CGRect frame = self.hostLabel.frame;
    CGFloat margin = frame.origin.y;
    CGSize size = [self.hostLabel sizeThatFits:CGSizeMake(width, frame.size.height)];
    frame.size.width = MIN(size.width, width * 0.8);
    frame.origin.x = (width - size.width + iconWidth - 1) * 0.5;
    self.hostLabel.frame = frame;
    yoffset += CGRectGetMidY(frame);
    self.hostLabel.alpha = MAX(height - yoffset, 0)/frame.size.height;

    self.secureIcon.alpha = self.hostLabel.alpha;
    self.secureIcon.center = CGPointMake(frame.origin.x - iconWidth*0.5 - 4, self.hostLabel.center.y);

    yoffset += margin;
    CGFloat bottom = self.tipsLabel.bounds.size.height + margin * 2;
    self.refreshIcon.center = CGPointMake(width * 0.5, (MIN(height, kRefreshMaxHeight-bottom) + yoffset) * 0.5);
    self.refreshIcon.alpha = MIN(MAX((height - yoffset)/kRefreshLogoSize - 1, 0), 1);
    CGFloat rate = (self.refreshIcon.center.y - yoffset) * 2 / (kRefreshMaxHeight-bottom-yoffset);
    self.refreshIcon.transform = CGAffineTransformMakeRotation((rate * 1.5 + 1) * M_PI);

    rate = MIN(MAX(height - (kRefreshMaxHeight-bottom), 0)/bottom, 1);
    CGFloat bgSize = rate * kRefreshButton;
    self.refreshIconBG.center = self.refreshIcon.center;
    self.refreshIconBG.bounds = CGRectMake(0, 0, bgSize, bgSize);
    self.refreshIconBG.layer.cornerRadius = bgSize * 0.5;

    frame = self.tipsLabel.frame;
    frame.size.width = width;
    frame.origin.y = self.refreshIconBG.center.y + kRefreshButton*0.5 + margin * 2;
    self.tipsLabel.frame = frame;
    self.tipsLabel.alpha = rate;
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    [self.scrollView.panGestureRecognizer addTarget:self action:@selector(actionPanGestureRecognizer:)];
}

- (void)removeFromSuperview {
    [self.scrollView.panGestureRecognizer removeTarget:self action:@selector(actionPanGestureRecognizer:)];
    [super removeFromSuperview];
}

- (void)sendActionsForControlEvents:(UIControlEvents)controlEvents {
    if (controlEvents == UIControlEventValueChanged) {
        _activeOffset = MAX(-self.scrollView.contentOffset.y, 0);
        [super endRefreshing]; // Note: Disable default value changed
    } else {
        [super sendActionsForControlEvents:controlEvents];
    }
}

- (void)beginRefreshing {
    // Do nothing
}

- (void)setHost:(NSString *)host {
    if (![_host isEqualToString:host]) {
        _host = host;
        self.hostLabel.text = host;
        [self setNeedsLayout];
    }
}

- (void)setHasOnlySecureContent:(BOOL)hasOnlySecureContent {
    if (_hasOnlySecureContent != hasOnlySecureContent) {
        _hasOnlySecureContent = hasOnlySecureContent;

        CHTheme *theme = CHTheme.shared;
        if (hasOnlySecureContent) {
            self.secureIcon.tintColor = theme.secureColor;
            self.secureIcon.image = [UIImage systemImageNamed:@"lock.fill"];
        } else {
            self.secureIcon.tintColor = theme.warnColor;
            self.secureIcon.image = [UIImage systemImageNamed:@"exclamationmark.triangle.fill"];
        }
    }
}

#pragma mark - Action Methods
- (void)actionPanGestureRecognizer:(UIPanGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded && MAX(-self.scrollView.contentOffset.y, 0) >= self.activeOffset) {
        @weakify(self);
        dispatch_main_after(kCHAnimateSlowDuration, ^{
            @strongify(self);
            [self sendRefreshChanged];
        });
    }
}

#pragma mark - Private Methods
- (UIScrollView *)scrollView {
    UIScrollView *scrollView = nil;
    if ([self.superview isKindOfClass:UIScrollView.class]) {
        scrollView = (UIScrollView *)self.superview;
    }
    return scrollView;
}

- (void)sendRefreshChanged {
    [super sendActionsForControlEvents:UIControlEventValueChanged];
}


@end
