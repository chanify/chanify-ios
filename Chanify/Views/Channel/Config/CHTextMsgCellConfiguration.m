//
//  CHTextMsgCellConfiguration.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHTextMsgCellConfiguration.h"
#import <M80AttributedLabel/M80AttributedLabel.h>
#import "CHRouter.h"
#import "CHTheme.h"

static UIFont *textFont;
static UIEdgeInsets textInsets = { 8, 12, 8, 12 };

@interface CHTextMsgCellConfiguration ()

@property (nonatomic, readonly, strong) NSString *text;
@property (nonatomic, readonly, assign) CGRect textRect;

@end

@interface CHTextMsgCellContentView : CHMsgCellContentView<CHTextMsgCellConfiguration *>

@property (nonatomic, readonly, strong) M80AttributedLabel *textLabel;

@end

@interface CHTextMsgCellContentView () <M80AttributedLabelDelegate>

@property (nonatomic, readonly, strong) UILongPressGestureRecognizer *longPressRecognizer;

@end

@implementation CHTextMsgCellContentView

- (void)dealloc {
    if (self.longPressRecognizer != nil) {
        [self removeGestureRecognizer:self.longPressRecognizer];
        _longPressRecognizer = nil;
    }
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)setupViews {
    CHTheme *theme = CHTheme.shared;

    M80AttributedLabel *textLabel = [[M80AttributedLabel alloc] initWithFrame:CGRectZero];
    [self.bubbleView addSubview:(_textLabel = textLabel)];
    textLabel.backgroundColor = UIColor.clearColor;
    textLabel.textColor = theme.labelColor;
    textLabel.linkColor = theme.tintColor;
    textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    textLabel.autoDetectLinks = YES;
    textLabel.numberOfLines = 0;
    textLabel.font = textFont;
    textLabel.delegate = self;

    UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(actionLongPress:)];
    [self addGestureRecognizer:(_longPressRecognizer = longPressRecognizer)];
    self.userInteractionEnabled = YES;
}

- (void)applyConfiguration:(CHTextMsgCellConfiguration *)configuration {
    self.textLabel.text = configuration.text;
    self.textLabel.frame = configuration.textRect;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    if (previousTraitCollection.userInterfaceStyle != self.traitCollection.userInterfaceStyle) {
        // Note: Fix dark mode for M80AttributedLabel
        self.textLabel.text = [(CHTextMsgCellConfiguration *)self.configuration text];
        [self setNeedsDisplay];
    }
    [super traitCollectionDidChange:previousTraitCollection];
}

#pragma mark - M80AttributedLabelDelegate
- (void)m80AttributedLabel:(M80AttributedLabel *)label clickedOnLink:(id)linkData {
    UIMenuController *menu = UIMenuController.sharedMenuController;
    if (menu.isMenuVisible) {
        [menu hideMenuFromView:self.bubbleView];
    }
    if ([linkData isKindOfClass:NSString.class]) {
        NSURL *url = [NSURL URLWithString:(NSString *)linkData];
        if (url.scheme.length <= 0) {
            url = [NSURL URLWithString:[@"http://" stringByAppendingString:linkData]];
        }
        if (url.scheme.length > 0) {
            [CHRouter.shared handleURL:url];
        }
    }
}

#pragma mark - Action Methods
- (void)actionLongPress:(UILongPressGestureRecognizer *)recognizer {
    [self becomeFirstResponder];

    UIMenuController *menu = UIMenuController.sharedMenuController;
    UIMenuItem *copyItem = [[UIMenuItem alloc]initWithTitle:@"Copy".localized action:@selector(actionCopy:)];
    UIMenuItem *shareItem = [[UIMenuItem alloc]initWithTitle:@"Share".localized action:@selector(actionShare:)];
    menu.menuItems = @[copyItem, shareItem];
    [menu showMenuFromView:self.bubbleView rect:self.textLabel.frame];
}

- (void)actionCopy:(id)sender {
    UIPasteboard.generalPasteboard.string = self.textLabel.text;
    [CHRouter.shared makeToast:@"Copied".localized];
}

- (void)actionShare:(id)sender {
    [CHRouter.shared showShareItem:@[[(CHTextMsgCellConfiguration *)self.configuration text]] sender:sender handler:nil];
}


@end

@implementation CHTextMsgCellConfiguration

+ (void)initialize {
    textFont = [UIFont systemFontOfSize:16];
}

+ (instancetype)cellConfiguration:(CHMessageModel *)model {
    return [[self.class alloc] initWithMID:model.mid text:model.text textRC:CGRectZero bubbleRC:CGRectZero];
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [[self.class allocWithZone:zone] initWithMID:self.mid text:self.text textRC:self.textRect bubbleRC:self.bubbleRect];
}

- (instancetype)initWithMID:(uint64_t)mid text:(NSString * _Nullable)text textRC:(CGRect)textRect bubbleRC:(CGRect)bubbleRect {
    if (self = [super initWithMID:mid bubbleRect:bubbleRect]) {
        _text = (text == nil ? @"" : text);
        _textRect = textRect;
    }
    return self;
}

- (__kindof UIView<UIContentView> *)makeContentView {
    return [[CHTextMsgCellContentView alloc] initWithConfiguration:self];
}

- (CGSize)calcContentSize:(CGSize)size {
    if (CGRectIsEmpty(self.textRect)) {
        _textRect.origin.x = textInsets.left;
        _textRect.origin.y = textInsets.top;
        NSAttributedString *text = [[NSAttributedString alloc] initWithString:self.text attributes:@{
            NSFontAttributeName: textFont,
        }];
        CGRect rc = [text boundingRectWithSize:CGSizeMake(size.width - textInsets.left - textInsets.right, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading context:nil];
        _textRect.size.width = ceil(rc.size.width);
        _textRect.size.height = ceil(rc.size.height);
    }
    return CGSizeMake(self.textRect.size.width + textInsets.left + textInsets.right, self.textRect.size.height + textInsets.top + textInsets.bottom);
}


@end
