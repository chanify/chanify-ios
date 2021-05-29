//
//  CHAudioPlayer.m
//  iOS
//
//  Created by WizJin on 2021/5/28.
//

#import "CHAudioPlayer.h"
#import <AVFAudio/AVFAudio.h>
#import <MediaPlayer/MediaPlayer.h>

@interface CHAudioPlayer () <AVAudioPlayerDelegate>

@property (nonatomic, readonly, strong) AVAudioPlayer *audioPlayer;

@end

@implementation CHAudioPlayer

+ (instancetype)shared {
    static CHAudioPlayer *player;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        player = [CHAudioPlayer new];
    });
    return player;
}

- (instancetype)init {
    if (self = [super init]) {
        _audioPlayer = nil;

        AVAudioSession *session = AVAudioSession.sharedInstance;
        [session setCategory:AVAudioSessionCategoryPlayback error:nil];
        [session setActive:YES error:nil];
        
        MPRemoteCommandCenter *commandCenter = MPRemoteCommandCenter.sharedCommandCenter;
        [commandCenter.playCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
            if (self.audioPlayer != nil) {
                [self.audioPlayer play];
                return MPRemoteCommandHandlerStatusSuccess;
            }
            return MPRemoteCommandHandlerStatusCommandFailed;
        }];
        [commandCenter.pauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
            if (self.audioPlayer != nil) {
                [self.audioPlayer pause];
                return MPRemoteCommandHandlerStatusSuccess;
            }
            return MPRemoteCommandHandlerStatusCommandFailed;
        }];
    }
    return self;
}

- (uint64_t)durationForURL:(NSURL *)url {
    uint64_t res = 0;
    AVAudioPlayer* player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    if (player != nil) {
        double duration = player.duration;
        AVAudioFormat* format = player.format;
        if (format.sampleRate > 0) {
            duration = duration*(25600/format.sampleRate);
        }
        res = duration * 1000;
    }
    return res;
}

- (void)playWithURL:(NSURL *)url {
    if (_audioPlayer != nil && ![self.audioPlayer.url isEqual:url]) {
        [self stopAudioPlayer:self.audioPlayer];
    }
    if (_audioPlayer == nil) {
        NSError *error = nil;
        AVAudioPlayer *audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
        if (error == nil) {
            _audioPlayer = audioPlayer;
            audioPlayer.delegate = self;
            audioPlayer.numberOfLoops = 0;
            [audioPlayer prepareToPlay];
        }
    }
    if (_audioPlayer != nil) {
        [_audioPlayer play];
    }
}

#pragma mark - AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    if (!flag) {
        [self stopAudioPlayer:player];
    }
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    [self stopAudioPlayer:player];
}

#pragma mark - Private Methods
- (void)stopAudioPlayer:(AVAudioPlayer *)player {
    if (_audioPlayer != nil && player == _audioPlayer) {
        [_audioPlayer stop];
        _audioPlayer = nil;
    }
}


@end
