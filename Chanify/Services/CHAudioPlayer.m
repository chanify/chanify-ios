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
@property (nonatomic, readonly, assign) BOOL isResetAudioCategory;
@property (nonatomic, nullable, strong) NSTimer *trackTimer;
@property (nonatomic, nullable, strong) NSURL *audioUrl;
@property (nonatomic, nullable, strong) NSString *title;

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
        _trackTimer = nil;
        _audioUrl = nil;
        _title = nil;
        _isResetAudioCategory = NO;

        MPRemoteCommandCenter *commandCenter = MPRemoteCommandCenter.sharedCommandCenter;
        [commandCenter.playCommand addTarget:self action:@selector(actionPlayCommand:)];
        [commandCenter.pauseCommand addTarget:self action:@selector(actionPauseCommand:)];
        [commandCenter.togglePlayPauseCommand addTarget:self action:@selector(actionTogglePlayPauseCommand:)];
        [commandCenter.skipForwardCommand addTarget:self action:@selector(actionSkipForwardCommand:)];
        [commandCenter.skipBackwardCommand addTarget:self action:@selector(actionSkipBackwardCommand:)];
        [commandCenter.changePlaybackPositionCommand addTarget:self action:@selector(actionChangePositionCommand:)];
    }
    return self;
}

- (uint64_t)durationForURL:(NSURL *)url {
    uint64_t res = 0;
    AVAudioPlayer* audioPlayer = createPlayerWithURL(url);
    if (audioPlayer != nil) {
        res = audioPlayer.duration * 1000;
    }
    return res;
}

- (void)playWithURL:(NSURL *)url title:(nullable NSString *)title {
    if (_audioPlayer != nil && ![self.audioPlayer.url isEqual:url]) {
        [self stopAudioPlayer:self.audioPlayer];
    }
    if (_audioPlayer == nil) {
        AVAudioPlayer* audioPlayer = createPlayerWithURL(url);
        if (audioPlayer != nil) {
            [self resetAudioCategory];
            _title = title;
            _audioUrl = url;
            _audioPlayer = audioPlayer;
            audioPlayer.delegate = self;
            audioPlayer.numberOfLoops = 0;
            [audioPlayer prepareToPlay];
            NSMutableDictionary *info = [NSMutableDictionary dictionaryWithDictionary:@{
                MPMediaItemPropertyPlaybackDuration: @(audioPlayer.duration),
                MPNowPlayingInfoPropertyElapsedPlaybackTime: @(audioPlayer.currentTime),
            }];
            if (self.title.length > 0) {
                [info setObject:self.title forKey:MPMediaItemPropertyTitle];
            }
            MPNowPlayingInfoCenter.defaultCenter.nowPlayingInfo = info;
        }
    }
    [self play];
}

- (nullable NSURL *)currentURL {
    if (_audioPlayer != nil) {
        return self.audioUrl ?: _audioPlayer.url;
    }
    return nil;
}

- (NSNumber *)audioTrack {
    if (_audioPlayer != nil) {
        NSTimeInterval duration = _audioPlayer.duration;
        if (duration > 0) {
            return @(_audioPlayer.currentTime/duration);
        }
    }
    return @(0);
}

- (BOOL)isPlaying {
    return (_audioPlayer != nil && _audioPlayer.isPlaying);
}

- (void)play {
    if (_audioPlayer != nil && !_audioPlayer.isPlaying) {
        [self startTimer];
        [_audioPlayer play];
        [self updatePlayStatus];
    }
}

- (void)pause {
    if (_audioPlayer != nil && _audioPlayer.isPlaying) {
        [_audioPlayer pause];
        [self stopTimer];
        [self updatePlayStatus];
    }
}

- (void)stop {
    if (_audioPlayer != nil && _audioPlayer.isPlaying) {
        [self stopAudioPlayer:_audioPlayer];
    }
}

#pragma mark - AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    if (flag) {
        self.audioPlayer.currentTime = 0;
        [self updatePlayStatus];
    } else {
        [self stopAudioPlayer:player];
    }
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    [self stopAudioPlayer:player];
}

#pragma mark - Action Methods
- (MPRemoteCommandHandlerStatus)actionPlayCommand:(MPRemoteCommandEvent *)event {
    if (self.audioPlayer != nil) {
        [self play];
        return MPRemoteCommandHandlerStatusSuccess;
    }
    return MPRemoteCommandHandlerStatusCommandFailed;
}

- (MPRemoteCommandHandlerStatus)actionPauseCommand:(MPRemoteCommandEvent *)event {
    if (self.audioPlayer != nil) {
        [self pause];
        return MPRemoteCommandHandlerStatusSuccess;
    }
    return MPRemoteCommandHandlerStatusCommandFailed;
}

- (MPRemoteCommandHandlerStatus)actionTogglePlayPauseCommand:(MPRemoteCommandEvent *)event {
    if (self.audioPlayer != nil) {
        if (self.isPlaying) {
            [self pause];
        } else {
            [self play];
        }
        return MPRemoteCommandHandlerStatusSuccess;
    }
    return MPRemoteCommandHandlerStatusCommandFailed;
}

- (MPRemoteCommandHandlerStatus)actionSkipForwardCommand:(MPSkipIntervalCommandEvent *)event {
    if (self.audioPlayer != nil) {
        self.audioPlayer.currentTime = self.audioPlayer.currentTime + event.interval;
        [self updateTrackChanged];
        return MPRemoteCommandHandlerStatusSuccess;
    }
    return MPRemoteCommandHandlerStatusCommandFailed;
}

- (MPRemoteCommandHandlerStatus)actionSkipBackwardCommand:(MPSkipIntervalCommandEvent *)event {
    if (self.audioPlayer != nil) {
        self.audioPlayer.currentTime = MAX(self.audioPlayer.currentTime - event.interval, 0);
        [self updateTrackChanged];
        return MPRemoteCommandHandlerStatusSuccess;
    }
    return MPRemoteCommandHandlerStatusCommandFailed;
}

- (MPRemoteCommandHandlerStatus)actionChangePositionCommand:(MPChangePlaybackPositionCommandEvent *)event {
    if (self.audioPlayer != nil) {
        self.audioPlayer.currentTime = event.positionTime;
        [self updateTrackChanged];
        return MPRemoteCommandHandlerStatusSuccess;
    }
    return MPRemoteCommandHandlerStatusCommandFailed;
}

#pragma mark - Private Methods
- (void)resetAudioCategory {
#if TARGET_OS_IOS
    if (!self.isResetAudioCategory) {
        _isResetAudioCategory = YES;
        AVAudioSession *session = AVAudioSession.sharedInstance;
        [session setCategory:AVAudioSessionCategoryPlayback error:nil];
        [session setActive:YES error:nil];
    }
#endif
}

- (void)onTimer:(id)sender {
    [self updateTrackChanged];
}

- (void)startTimer {
    if (_trackTimer == nil) {
        _trackTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
    }
}

- (void)stopTimer {
    if (_trackTimer != nil) {
        [_trackTimer invalidate];
        _trackTimer = nil;
    }
}

- (void)stopAudioPlayer:(AVAudioPlayer *)player {
    if (_audioPlayer != nil && player == _audioPlayer) {
        [_audioPlayer stop];
        [self stopTimer];
        [self updatePlayStatus];
        _title = nil;
        _audioUrl = nil;
        _audioPlayer = nil;
    }
}

- (void)updateTrack {
    if (_audioPlayer != nil) {
        MPNowPlayingInfoCenter *center = MPNowPlayingInfoCenter.defaultCenter;
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithDictionary:center.nowPlayingInfo];
        NSTimeInterval currentTime = self.audioPlayer.currentTime;
        if ([[info valueForKey:MPNowPlayingInfoPropertyElapsedPlaybackTime] doubleValue] != currentTime) {
            [info setValue:@(currentTime) forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
            center.nowPlayingInfo = info;
        }
    }
}

- (void)updateTrackChanged {
    [self updateTrack];
    [self sendNotifyWithSelector:@selector(audioPlayTrackChanged:) withObject:self];
}

- (void)updatePlayStatus {
    if (_audioPlayer != nil) {
        [self updateTrack];
    }
    [self sendNotifyWithSelector:@selector(audioPlayStatusChanged:) withObject:self];
}

static inline AVAudioPlayer *createPlayerWithURL(NSURL *url) {
    NSError *error = nil;
    AVAudioPlayer* player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    if (error != nil) {
        player = nil;
        NSData *data = [[NSData alloc] initWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:&error];
        if (data.length > 0) {
            error = nil;
            player = [[AVAudioPlayer alloc] initWithData:data fileTypeHint:AVFileTypeMPEGLayer3 error:&error];
            if (error != nil) {
                player = nil;
            }
        }
    }
    return player;
}


@end
