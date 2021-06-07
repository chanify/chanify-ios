//
//  CHMessageCellItem.m
//  OSX
//
//  Created by WizJin on 2021/6/7.
//

#import "CHMessageCellItem.h"

@implementation CHMenuController : NSObject

+ (instancetype)sharedMenuController {
    return nil;
}

- (void)showMenuFromView:(CHView *)targetView rect:(CGRect)targetRect {
    
}

- (BOOL)isMenuVisible {
    return NO;
}

- (void)hideMenuFromView:(CHView *)targetView {
    
}

@end

@implementation NSMenuItem (CHExt)

- (instancetype)initWithTitle:(NSString *)title action:(SEL)action {
    if (self = [self init]) {
        
    }
    return self;
}

@end

@implementation CHTapGestureRecognizer

- (void)requireGestureRecognizerToFail:(NSGestureRecognizer *)otherGestureRecognizer {
    
}

@end

@implementation CHLongPressGestureRecognizer

- (instancetype)initWithTarget:(id)target action:(SEL)action {
    if (self = [super initWithTarget:target action:action]) {
        self.buttonMask = 0x02;    // Right button click
    }
    return self;
}

@end

#import "CHActionMsgCellConfiguration.h"
@implementation CHActionMsgCellConfiguration

+ (instancetype)cellConfiguration:(CHMessageModel *)model {
    return [[self.class alloc] initWithMID:model.mid];
}
@end

#import "CHFileMsgCellConfiguration.h"
@implementation CHFileMsgCellConfiguration

+ (instancetype)cellConfiguration:(CHMessageModel *)model {
    return [[self.class alloc] initWithMID:model.mid];
}
@end

#import "CHImageMsgCellConfiguration.h"
@implementation CHImageMsgCellConfiguration

+ (instancetype)cellConfiguration:(CHMessageModel *)model {
    return [[self.class alloc] initWithMID:model.mid];
}
@end

#import "CHLinkMsgCellConfiguration.h"
@implementation CHLinkMsgCellConfiguration

+ (instancetype)cellConfiguration:(CHMessageModel *)model {
    return [[self.class alloc] initWithMID:model.mid];
}
@end

#import "CHAudioMsgCellConfiguration.h"
@implementation CHAudioMsgCellConfiguration

+ (instancetype)cellConfiguration:(CHMessageModel *)model {
    return [[self.class alloc] initWithMID:model.mid];
}
@end
