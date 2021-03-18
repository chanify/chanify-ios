//
//  CHMsgCellConfiguration.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHMsgCellConfiguration.h"
#import "CHRouter.h"
#import "CHLogic.h"
#import "CHTheme.h"

@implementation CHMsgCellConfiguration

static UIEdgeInsets bubbleInsets = { 0, 20, 0, 30 };

- (instancetype)initWithMID:(NSString *)mid bubbleRect:(CGRect)bubbleRect {
    if (self = [super initWithMID:mid]) {
        _bubbleRect = bubbleRect;
    }
    return self;
}

- (void)setNeedRecalcLayout {
    _bubbleRect = CGRectZero;
    [self setNeedRecalcContentLayout];
}

- (void)setNeedRecalcContentLayout {
}

- (CGFloat)calcHeight:(CGSize)size {
    if (CGRectIsEmpty(self.bubbleRect)) {
        _bubbleRect.origin.x = bubbleInsets.left;
        _bubbleRect.origin.y = bubbleInsets.top;
        _bubbleRect.size.width = size.width - bubbleInsets.left - bubbleInsets.right;
        _bubbleRect.size.height = size.height - bubbleInsets.top - bubbleInsets.bottom;
        CGSize sz = [self calcContentSize:self.bubbleRect.size];
        _bubbleRect.size.width = MIN(sz.width, size.width);
        _bubbleRect.size.height = MAX(sz.height, size.height);
    }
    return self.bubbleRect.size.height + bubbleInsets.top + bubbleInsets.bottom;
}

- (CGSize)calcContentSize:(CGSize)size {
    return size;
}

@end

@interface CHMsgCellContentView ()

@property (nonatomic, readonly, strong) UILongPressGestureRecognizer *longPressRecognizer;

@end

@implementation CHMsgCellContentView

- (instancetype)initWithConfiguration:(CHMsgCellConfiguration *)configuration {
    if (self = [super initWithFrame:CGRectZero]) {
        _configuration = nil;
        
        UIView *bubbleView = [UIView new];
        [self addSubview:(_bubbleView = bubbleView)];
        bubbleView.backgroundColor = CHTheme.shared.bubbleBackgroundColor;
        bubbleView.layer.cornerRadius = 8;
        
        [self setupViews];
        
        UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(actionLongPress:)];
        [self addGestureRecognizer:(_longPressRecognizer = longPressRecognizer)];
        self.userInteractionEnabled = YES;
        
        self.configuration = configuration;
    }
    return self;
}

- (void)dealloc {
    if (self.longPressRecognizer != nil) {
        [self removeGestureRecognizer:self.longPressRecognizer];
        _longPressRecognizer = nil;
    }
}

- (void)setConfiguration:(CHMsgCellConfiguration *)configuration {
    _configuration = configuration;
    [self applyConfiguration:configuration];
}

- (void)applyConfiguration:(CHMsgCellConfiguration *)configuration {
    self.bubbleView.frame = configuration.bubbleRect;
}

- (void)setupViews {
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}


#pragma mark - Actions Methods
- (void)actionLongPress:(UILongPressGestureRecognizer *)recognizer {
    [self becomeFirstResponder];

    UIMenuController *menu = UIMenuController.sharedMenuController;
    menu.menuItems = self.menuActions;
    [menu showMenuFromView:self.bubbleView rect:self.bubbleView.bounds];
}

- (NSArray<UIMenuItem *> *)menuActions {
    UIMenuItem *deleteItem = [[UIMenuItem alloc]initWithTitle:@"Delete".localized action:@selector(actionDelete:)];
    return @[deleteItem];
}

- (void)actionDelete:(id)sender {
    NSString *mid = self.configuration.mid;
    if (mid.length > 0) {
        [CHRouter.shared showAlertWithTitle:@"Delete this message or not?".localized action:@"Delete".localized handler:^{
            [CHLogic.shared deleteMessage:mid];
        }];
    }
}


@end
