//
//  CHAudioPlayer.h
//  iOS
//
//  Created by WizJin on 2021/5/28.
//

#import "CHManager.h"

NS_ASSUME_NONNULL_BEGIN

@class CHAudioPlayer;

@protocol CHAudioPlayerDelegate <NSObject>

- (void)audioPlayStatusChanged:(CHAudioPlayer *)audioPlayer;
- (void)audioPlayTrackChanged:(CHAudioPlayer *)audioPlayer;

@end

@interface CHAudioPlayer : CHManager<id<CHAudioPlayerDelegate>>

+ (instancetype)shared;
- (uint64_t)durationForURL:(NSURL *)url;
- (void)playWithURL:(NSURL *)url title:(nullable NSString *)title;
- (nullable NSURL *)currentURL;
- (NSNumber *)audioTrack;
- (BOOL)isPlaying;
- (void)pause;
- (void)stop;


@end

NS_ASSUME_NONNULL_END
