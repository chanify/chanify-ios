//
//  CHLinkLabel.h
//  Chanify
//
//  Created by WizJin on 2021/6/7.
//

#import "CHUI.h"

NS_ASSUME_NONNULL_BEGIN

#if TARGET_OS_OSX
@interface CHLinkLabel : NSTextView

@property (nonatomic, nullable, strong) NSString *text;

#else
@interface CHLinkLabel : UITextView
#endif

@property (nonatomic, nullable, strong) CHColor *linkColor;

- (NSString *)linkForPoint:(CGPoint)point;
- (NSString *)selectedText;
- (void)resetSelectText;


@end

NS_ASSUME_NONNULL_END
