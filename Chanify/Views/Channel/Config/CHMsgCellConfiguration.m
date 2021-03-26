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

- (instancetype)initWithMID:(NSString *)mid {
    if (self = [super initWithMID:mid]) {
    }
    return self;
}

- (CGFloat)calcHeight:(CGSize)size {
    return size.height;
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
}

- (void)setupViews {
}

- (UIView *)contentView {
    return self;
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}


#pragma mark - Actions Methods
- (void)actionLongPress:(UILongPressGestureRecognizer *)recognizer {
    UIView *contentView = self.contentView;
    if (contentView != nil) {
        [self becomeFirstResponder];

        UIMenuController *menu = UIMenuController.sharedMenuController;
        menu.menuItems = self.menuActions;
        [menu showMenuFromView:contentView rect:contentView.bounds];
    }
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
