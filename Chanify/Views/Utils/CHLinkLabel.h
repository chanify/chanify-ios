//
//  CHLinkLabel.h
//  Chanify
//
//  Created by WizJin on 2021/6/7.
//

#import "CHUI.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHLinkLabel : CHTextView

#if TARGET_OS_OSX
@property (nonatomic, nullable, strong) NSString *text;
#endif

@property (nonatomic, nullable, strong) CHColor *linkColor;

- (NSString *)linkForPoint:(CGPoint)point;
- (NSString *)selectedText;
- (void)resetSelectText;
- (void)clearSelectedText;


@end

NS_ASSUME_NONNULL_END
