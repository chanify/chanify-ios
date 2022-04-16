//
//  CHActionMsgCellConfiguration.m
//  iOS
//
//  Created by WizJin on 2021/5/13.
//

#import "CHActionMsgCellConfiguration.h"
#import "CHActionGroup.h"
#import "CHPasteboard.h"
#import "CHRouter.h"
#import "CHTheme.h"

@interface CHActionMsgCellConfiguration ()

@property (nonatomic, readonly, nullable, strong) NSArray<CHActionItemModel *> *actions;

@end

@interface CHActionMsgCellContentView : CHTextMsgCellContentView

@property (nonatomic, readonly, strong) CHActionGroup *actionGroup;

@end

@interface CHActionMsgCellContentView () <CHActionGroupDelegate>

@end

@implementation CHActionMsgCellContentView

- (void)setupViews {
    [super setupViews];

    CHActionGroup *actionGroup = [CHActionGroup new];
    [self.bubbleView addSubview:(_actionGroup = actionGroup)];
    actionGroup.delegate = self;
}

- (void)applyConfiguration:(CHActionMsgCellConfiguration *)configuration {
    self.actionGroup.actions = configuration.actions;
    [super applyConfiguration:configuration];
    CGSize size = configuration.bubbleRect.size;
    CGFloat defaultHeight = CHActionGroup.defaultHeight;
    self.actionGroup.frame = CGRectMake(0, size.height - defaultHeight, size.width, defaultHeight);
}

- (BOOL)canGestureRecognizer:(CHGestureRecognizer *)recognizer {
    if (CGRectContainsPoint(self.actionGroup.bounds, [recognizer locationInView:self.actionGroup])) {
        return NO;
    }
    return [super canGestureRecognizer:recognizer];
}

#pragma mark - CHActionGroupDelegate
- (void)actionGroupSelected:(nullable CHActionItemModel *)item {
    NSURL *link = item.link;
    if (link == nil) {
        [CHRouter.shared makeToast:@"Can't open url".localized];
    } else {
        [CHRouter.shared handleURL:link];
    }
}


@end

@implementation CHActionMsgCellConfiguration

+ (instancetype)cellConfiguration:(CHMessageModel *)model {
    return [[self.class alloc] initWithMID:model.mid text:model.text title:model.title textRect:CGRectZero titleRect:CGRectZero actions:model.actions bubbleRect:CGRectZero];
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [[self.class allocWithZone:zone] initWithMID:self.mid text:self.text title:self.title textRect:self.textRect titleRect:self.titleRect actions:self.actions bubbleRect:self.bubbleRect];
}

- (instancetype)initWithMID:(NSString *)mid text:(NSString * _Nullable)text title:(NSString * _Nullable)title textRect:(CGRect)textRect titleRect:(CGRect)titleRect actions:(NSArray<CHActionItemModel *> *)actions bubbleRect:(CGRect)bubbleRect {
    if (self = [super initWithMID:mid text:text title:title textRect:textRect titleRect:titleRect bubbleRect:bubbleRect]) {
        _actions = actions;
    }
    return self;
}

- (__kindof CHView<CHContentView> *)makeContentView {
    return [[CHActionMsgCellContentView alloc] initWithConfiguration:self];
}

- (CGSize)calcContentSize:(CGSize)size {
    size = [super calcContentSize:CGSizeMake(MAX(size.width, 300), size.height)];
    if (size.height > 0) {
        size.height += CHActionGroup.defaultHeight;
    }
    return CGSizeMake(MAX(size.width, 300), size.height);
}


@end
