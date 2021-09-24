//
//  CHBarButtonItem.h
//  OSX
//
//  Created by WizJin on 2021/9/24.
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHBarButtonItem : NSButton

+ (instancetype)itemWithIcon:(NSString *)icon target:(id)target action:(SEL)action;


@end

NS_ASSUME_NONNULL_END
