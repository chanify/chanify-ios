//
//  CHAudioPlayer.h
//  iOS
//
//  Created by WizJin on 2021/5/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHAudioPlayer : NSObject

+ (instancetype)shared;
- (void)playWithURL:(NSURL *)url;


@end

NS_ASSUME_NONNULL_END
