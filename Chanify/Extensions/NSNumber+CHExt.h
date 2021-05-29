//
//  NSNumber+CHExt.h
//  Chanify
//
//  Created by WizJin on 2021/4/14.
//

#import <Foundation/NSString.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSNumber (CHExt)

- (NSString *)formatFileSize;
- (NSString *)formatDuration;


@end

NS_ASSUME_NONNULL_END
