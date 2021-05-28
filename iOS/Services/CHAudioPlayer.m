//
//  CHAudioPlayer.m
//  iOS
//
//  Created by WizJin on 2021/5/28.
//

#import "CHAudioPlayer.h"
#import <AVFAudio/AVFAudio.h>

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
        AVAudioSession *session = AVAudioSession.sharedInstance;
        [session setCategory:AVAudioSessionCategoryPlayback error:nil];
        [session setActive:YES error:nil];
        
        _audioPlayer = nil;
    }
    return self;
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
            audioPlayer.numberOfLoops = 1;
            [audioPlayer prepareToPlay];
            [UIApplication.sharedApplication beginReceivingRemoteControlEvents];
            [audioPlayer play];
        }
    }
}

#pragma mark - AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    [self stopAudioPlayer:player];
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    [self stopAudioPlayer:player];
}

#pragma mark - Private Methods
- (void)stopAudioPlayer:(AVAudioPlayer *)player {
    if (_audioPlayer != nil && player == _audioPlayer) {
        [UIApplication.sharedApplication endReceivingRemoteControlEvents];
        [_audioPlayer stop];
        _audioPlayer = nil;
    }
}


@end
