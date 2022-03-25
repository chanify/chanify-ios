//
//  CHMsgCellConfiguration.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHMsgCellConfiguration.h"
#import "CHLogic.h"
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

@property (nonatomic, readonly, strong) CHLongPressGestureRecognizer *longPressRecognizer;
@property (nonatomic, readonly, strong) CHTapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, nullable, strong) CHImageView *checkIcon;

@end

@implementation CHMsgCellContentView

- (instancetype)initWithConfiguration:(CHMsgCellConfiguration *)configuration {
    if (self = [super initWithFrame:CGRectZero]) {
        _checkIcon = nil;
        _configuration = nil;
        
        [self setupViews];
        
        CHLongPressGestureRecognizer *longPressRecognizer = [[CHLongPressGestureRecognizer alloc] initWithTarget:self action:@selector(actionLongPress:)];
        CHTapGestureRecognizer *tapGestureRecognizer = [[CHTapGestureRecognizer alloc] initWithTarget:self action:@selector(actionTap:)];
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
    CHView *contentView = self.contentView;
    CGRect frame = contentView.frame;
    BOOL isEditing = self.source.isEditing;
    self.userInteractionEnabled = !isEditing;
    contentView.frame = CGRectMake((isEditing ? 50 : 20), 0, frame.size.width, frame.size.height);
    if (!isEditing) {
        if (self.checkIcon != nil) {
            [self.checkIcon removeFromSuperview];
            _checkIcon = nil;
        }
    } else {
        if (self.checkIcon == nil) {
            [self addSubview:(_checkIcon = [CHImageView new])];
        }
        self.checkIcon.frame = CGRectMake((50 - kCheckIconSize)/2, (frame.size.height - kCheckIconSize)/2, kCheckIconSize, kCheckIconSize);
    }
}

- (void)applyConfiguration:(CHMsgCellConfiguration *)configuration {
}
    
- (void)updateConfigurationUsingState:(CHCellConfigurationState *)state {
    if (self.source.isEditing) {
        [self setSelected:state.isSelected];
    }
}

- (void)setSelected:(BOOL)selected {
    if (self.checkIcon != nil) {
        if (selected) {
            self.checkIcon.image = [CHImage systemImageNamed:@"checkmark.circle.fill"];
            self.checkIcon.tintColor = CHTheme.shared.tintColor;
        } else {
            self.checkIcon.image = [CHImage systemImageNamed:@"circle"];
            self.checkIcon.tintColor = CHTheme.shared.minorLabelColor;
        }
    }
}

- (void)setupViews {
}

- (CHView *)contentView {
    return self;
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

#pragma mark - Actions Methods
- (void)actionTap:(CHTapGestureRecognizer *)recognizer {
    if (!self.source.isEditing) {
        [self.source activeMsgCellItem:self];
        if ([self canGestureRecognizer:recognizer]) {
            [self actionClicked:recognizer];
        }
    }
}

- (void)actionLongPress:(CHLongPressGestureRecognizer *)recognizer {
    if (!self.source.isEditing) {
        [self.source activeMsgCellItem:self];
        if ([self canGestureRecognizer:recognizer]) {
            CHView *contentView = self.contentView;
            CHMenuController *menu = CHMenuController.sharedMenuController;
            menu.menuItems = self.menuActions;
            CHView *target = [self actionPopMenu:recognizer];
            [menu showMenuFromView:contentView target:(target ?: self) point:[recognizer locationInView:contentView]];
        }
    }
}

- (BOOL)canGestureRecognizer:(CHGestureRecognizer *)recognizer {
    CHView *contentView = self.contentView;
    return (contentView != nil && CGRectContainsPoint(contentView.frame, [recognizer locationInView:self]));
}

- (void)actionClicked:(CHTapGestureRecognizer *)sender {
}

- (nullable CHView *)actionPopMenu:(CHLongPressGestureRecognizer *)recognizer {
    return nil;
}

- (NSArray<CHMenuItem *> *)menuActions {
    return @[
#if !TARGET_OS_OSX
        [[CHMenuItem alloc] initWithTitle:@"Select".localized action:@selector(actionSelect:)],
#endif
        [[CHMenuItem alloc] initWithTitle:@"Delete".localized action:@selector(actionDelete:)],
    ];
}

- (void)actionSelect:(id)sender {
    NSString *mid = self.configuration.mid;
    if (mid.length > 0) {
        [self.source beginEditingWithItem:self.configuration];
    }
}

- (void)actionDelete:(id)sender {
    [self.source activeMsgCellItem:nil];
    NSString *mid = self.configuration.mid;
    if (mid.length > 0) {
        [CHRouter.shared showAlertWithTitle:@"Delete this message or not?".localized action:@"Delete".localized handler:^{
            [CHLogic.shared deleteMessage:mid];
        }];
    }
}


@end
