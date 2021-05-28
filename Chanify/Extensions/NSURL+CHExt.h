//
//  NSURL+CHExt.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import <Foundation/NSURL.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURL (CHExt)

- (void)setDataProtoction:(NSString *)level;
- (uint64_t)fileSize;


@end

NS_ASSUME_NONNULL_END
