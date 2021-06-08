//
//  CHLinkLabel.h
//  OSX
//
//  Created by WizJin on 2021/6/7.
//

#import "CHUI.h"
#if TARGET_OS_OSX

NS_ASSUME_NONNULL_BEGIN
@interface CHLinkLabel : NSTextView

@property (nonatomic, nullable, strong) NSString *text;
@property (nonatomic, nullable, strong) CHColor *linkColor;


@end

NS_ASSUME_NONNULL_END

#else
#   import <M80AttributedLabel/M80AttributedLabel.h>

NS_ASSUME_NONNULL_BEGIN
@interface CHLinkLabel : M80AttributedLabel

@end

NS_ASSUME_NONNULL_END
#endif
