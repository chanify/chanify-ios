//
//  CHLinkLabel.m
//  OSX
//
//  Created by WizJin on 2021/6/7.
//

#import "CHLinkLabel.h"

#if TARGET_OS_OSX

@interface CHLinkLabel ()
@end

@implementation CHLinkLabel

- (instancetype)init {
    if (self = [super initWithFrame:CGRectZero]) {
        self.textContainer.lineBreakMode = NSLineBreakByCharWrapping;
        self.textContainer.lineFragmentPadding = 0;
        self.backgroundColor = NSColor.clearColor;
        self.automaticLinkDetectionEnabled = YES;
        self.selectable = NO;
        self.editable = NO;
    }
    return self;
}

- (void)setText:(NSString *)text {
    self.string = text;
    [self setEditable:YES];
    [self checkTextInDocument:nil];
    [self setEditable:NO];
}

- (NSString *)text {
    return self.string;
}

- (NSString *)linkForPoint:(CGPoint)point {
    return @"";
}


@end

#else

@interface M80AttributedLabel ()
@property (nonatomic,strong) NSMutableArray<M80AttributedLabelURL *> *linkLocations;
- (id)linkDataForPoint:(CGPoint)point;
@end

@implementation CHLinkLabel

- (instancetype)init {
    if (self = [super initWithFrame:CGRectZero]) {
        self.backgroundColor = UIColor.clearColor;
        self.userInteractionEnabled = NO;
        self.highlightColor = UIColor.clearColor;
        self.lineBreakMode = kCTLineBreakByWordWrapping;
        self.autoDetectLinks = YES;
        self.numberOfLines = 0;
    }
    return self;
}

- (NSString *)linkForPoint:(CGPoint)point {
    NSString *res = @"";
    NSUInteger n = self.linkLocations.count;
    if (n > 0) {
        id linkData = nil;
        if (n == 1) {
            linkData = self.linkLocations.firstObject.linkData;
        } else {
            linkData = [super linkDataForPoint:point];
        }
        if (linkData != nil && [linkData isKindOfClass:NSString.class]) {
            res = linkData;
        }
    }
    return res;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    return nil;
}


@end

#endif
