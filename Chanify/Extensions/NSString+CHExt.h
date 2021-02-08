//
//  NSString+CHExt.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import <Foundation/NSString.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (CHExt)

- (NSString *)localized;
- (NSString *)code;
- (const char *)cstr;


@end

NS_ASSUME_NONNULL_END
