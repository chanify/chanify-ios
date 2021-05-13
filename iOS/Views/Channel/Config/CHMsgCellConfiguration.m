//
//  CHMsgCellConfiguration.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHMsgCellConfiguration.h"
#import "CHMessagesDataSource.h"
#import "CHLogic+iOS.h"
#import "CHRouter.h"
#import "CHTheme.h"

#define kCheckIconSize  24

@implementation CHMsgCellConfiguration

- (instancetype)initWithMID:(NSString *)mid {
    if (self = [super initWithMID:mid]) {
    }
    return self;
}

- (CGSize)calcSize:(CGSize)size {
    return CGSizeMake(size.width - 60, size.height);
}

- (CGSize)calcContentSize:(CGSize)size {
    return size;
}


@end

@interface CHMsgCellContentView ()

@property (nonatomic, readonly, strong) UILongPressGestureRecognizer *longPressRecognizer;
@property (nonatomic, readonly, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, nullable, strong) UIImageView *checkIcon;

@end

@implementation CHMsgCellContentView

- (instancetype)initWithConfiguration:(CHMsgCellConfiguration *)configuration {
    if (self = [super initWithFrame:CGRectZero]) {
        _checkIcon = nil;
        _configuration = nil;
        
        [self setupViews];
        
        UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(actionLongPress:)];
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionTap:)];
        [tapGestureRecognizer requireGestureRecognizerToFail:longPressRecognizer];

        [self addGestureRecognizer:(_longPressRecognizer = longPressRecognizer)];
        [self addGestureRecognizer:(_tapGestureRecognizer = tapGestureRecognizer)];
        
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
    if (self.tapGestureRecognizer != nil) {
        [self removeGestureRecognizer:self.tapGestureRecognizer];
        _tapGestureRecognizer = nil;
    }
}

- (void)setConfiguration:(CHMsgCellConfiguration *)configuration {
    _configuration = configuration;
    [self applyConfiguration:configuration];
    CGRect frame = self.contentView.frame;
    BOOL isEditing = self.source.isEditing;
    self.userInteractionEnabled = !isEditing;
    self.contentView.frame = CGRectMake((isEditing ? 50 : 20), 0, frame.size.width, frame.size.height);
    if (!isEditing) {
        if (self.checkIcon != nil) {
            [self.checkIcon removeFromSuperview];
            _checkIcon = nil;
        }
    } else {
        if (self.checkIcon == nil) {
            [self addSubview:(_checkIcon = [UIImageView new])];
        }
        self.checkIcon.frame = CGRectMake((50 - kCheckIconSize)/2, (frame.size.height - kCheckIconSize)/2, kCheckIconSize, kCheckIconSize);
       
    }
}

- (void)applyConfiguration:(CHMsgCellConfiguration *)configuration {
}
    
- (void)updateConfigurationUsingState:(UICellConfigurationState *)state {
    if (self.source.isEditing) {
        [self setSelected:state.isSelected];
    }
}

- (void)setSelected:(BOOL)selected {
    if (self.checkIcon != nil) {
        if (selected) {
            self.checkIcon.image = [UIImage systemImageNamed:@"checkmark.circle.fill"];
            self.checkIcon.tintColor = CHTheme.shared.tintColor;
        } else {
            self.checkIcon.image = [UIImage systemImageNamed:@"circle"];
            self.checkIcon.tintColor = CHTheme.shared.minorLabelColor;
        }
    }
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
- (void)actionTap:(UITapGestureRecognizer *)recognizer {
    if (!self.source.isEditing && [self canGestureRecognizer:recognizer]) {
        [self actionClicked:recognizer];
    }
}

- (void)actionLongPress:(UILongPressGestureRecognizer *)recognizer {
    if (!self.source.isEditing && [self canGestureRecognizer:recognizer]) {
        [self becomeFirstResponder];
        UIView *contentView = self.contentView;
        UIMenuController *menu = UIMenuController.sharedMenuController;
        menu.menuItems = self.menuActions;
        [menu showMenuFromView:contentView rect:contentView.bounds];
    }
}

- (BOOL)canGestureRecognizer:(UIGestureRecognizer *)recognizer {
    UIView *contentView = self.contentView;
    return (contentView != nil && CGRectContainsPoint(self.contentView.frame, [recognizer locationInView:self]));
}

- (void)actionClicked:(UITapGestureRecognizer *)sender {
}

- (NSArray<UIMenuItem *> *)menuActions {
    return @[
        [[UIMenuItem alloc] initWithTitle:@"Select".localized action:@selector(actionSelect:)],
        [[UIMenuItem alloc] initWithTitle:@"Delete".localized action:@selector(actionDelete:)],
    ];
}

- (void)actionSelect:(id)sender {
    NSString *mid = self.configuration.mid;
    if (mid.length > 0) {
        [self.source beginEditingWiuthItem:self.configuration];
    }
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
