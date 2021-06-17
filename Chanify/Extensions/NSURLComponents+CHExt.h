//
//  NSURLComponents+CHExt.h
//  Chanify
//
//  Created by WizJin on 2021/6/18.
//

#import <Foundation/NSURL.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURLComponents (CHExt)

- (nullable NSString *)queryValueForName:(NSString *)name;


@end

NS_ASSUME_NONNULL_END
