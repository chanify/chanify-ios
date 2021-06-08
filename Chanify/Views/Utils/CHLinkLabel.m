//
//  CHLinkLabel.m
//  OSX
//
//  Created by WizJin on 2021/6/7.
//

#import "CHLinkLabel.h"

#if TARGET_OS_OSX

@implementation CHLinkLabel

- (instancetype)init {
    if (self = [super initWithFrame:CGRectZero]) {
        self.textContainer.lineBreakMode = NSLineBreakByCharWrapping;
        self.textContainer.lineFragmentPadding = 0;
        self.backgroundColor = NSColor.clearColor;
        self.editable = NO;
    }
    return self;
}

- (void)setText:(NSString *)text {
    self.string = text;
}

- (NSString *)text {
    return self.string;
}





@end

#else

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


@end

#endif
