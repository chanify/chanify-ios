//
//  CHBarButtonItem.m
//  OSX
//
//  Created by WizJin on 2021/9/24.
//

#import "CHBarButtonItem.h"
#import "CHTheme.h"

@implementation CHBarButtonItem

+ (instancetype)itemDoneWithTarget:(id)target action:(SEL)action {
    return [[self.class alloc] initDoneWithTarget:target action:action];
}

+ (instancetype)itemWithTitle:(NSString *)title target:(id)target action:(SEL)action {
    return [[self.class alloc] initWithTitle:title target:target action:action];
}

+ (instancetype)itemWithIcon:(NSString *)icon target:(id)target action:(SEL)action {
    return [[self.class alloc] initWithIcon:icon target:target action:action];
}

- (instancetype)initDoneWithTarget:(id)target action:(SEL)action {
    if (self = [super initWithFrame:NSMakeRect(0, 0, 50, 32)]) {
        self.contentTintColor = CHTheme.shared.labelColor;
        self.bezelStyle = NSBezelStyleTexturedSquare;
        self.showsBorderOnlyWhileMouseInside = YES;
        self.font = [CHFont systemFontOfSize:14];
        self.alignment = NSTextAlignmentCenter;
        self.title = @"Done".localized;
        self.target = target;
        self.action = action;
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)title target:(id)target action:(SEL)action {
    if (self = [super initWithFrame:NSMakeRect(0, 0, 32, 32)]) {
        self.contentTintColor = CHTheme.shared.labelColor;
        self.bezelStyle = NSBezelStyleTexturedSquare;
        self.showsBorderOnlyWhileMouseInside = YES;
        self.font = [CHFont boldSystemFontOfSize:20];
        self.title = title;
        self.target = target;
        self.action = action;
    }
    return self;
}

- (instancetype)initWithIcon:(NSString *)icon target:(id)target action:(SEL)action {
    if (self = [super initWithFrame:NSMakeRect(0, 0, 32, 32)]) {
        self.image = [CHImage systemImageNamed:icon];
        self.imageScaling = NSImageScaleProportionallyUpOrDown;
        self.contentTintColor = CHTheme.shared.labelColor;
        self.bezelStyle = NSBezelStyleTexturedSquare;
        self.showsBorderOnlyWhileMouseInside = YES;
        self.target = target;
        self.action = action;
    }
    return self;
}


@end
