//
//  CHBadgeView.m
//  Chanify
//
//  Created by WizJin on 2021/4/16.
//

#import "CHBadgeView.h"
#import "CHTheme.h"

@interface CHBadgeView ()

@property (nonatomic, readonly, strong) NSAttributedString *countText;

@end

@implementation CHBadgeView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = CHTheme.shared.alertColor;
        self.clipsToBounds = YES;
        self.hidden = YES;
        _count = 0;
        _countText = nil;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGSize size = self.bounds.size;
    self.layer.cornerRadius = MIN(size.width, size.height) * 0.5;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    if (self.countText != nil) {
        CGRect rc = [self.countText boundingRectWithSize:rect.size options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingTruncatesLastVisibleLine context:nil];
        rc.size.width = ceil(rc.size.width);
        rc.size.height = ceil(rc.size.height);
        rc.origin.x = (rect.size.width - rc.size.width) * 0.5;
        rc.origin.y = (rect.size.height - rc.size.height) * 0.5;
        [self.countText drawInRect:rc];
    }
}

- (void)setCount:(NSInteger)count {
    if (_count != count) {
        _count = count;
        NSString *value = @"";
        if (count <= 0) {
            self.hidden = YES;
        } else {
            self.hidden = NO;
            if (count > 99) {
                value = @"⋯";
            } else {
                value = [NSString stringWithFormat:@"%ld", (long)count];
            }
        }
        static NSDictionary *attributes = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            attributes = @{
                NSFontAttributeName: [UIFont boldSystemFontOfSize:10],
                NSForegroundColorAttributeName: UIColor.whiteColor,
            };
        });
        _countText = [[NSAttributedString alloc] initWithString:value attributes:attributes];
        [self setNeedsDisplay];
    }
}


@end
