//
//  CHAudioMsgCellConfiguration.m
//  iOS
//
//  Created by WizJin on 2021/5/27.
//

#import "CHAudioMsgCellConfiguration.h"
#import "CHWebAudioManager.h"
#import "CHAudioPlayer.h"
#import "CHRouter.h"
#import "CHLogic.h"
#import "CHTheme.h"

@interface CHAudioMsgCellConfiguration ()

@property (nonatomic, readonly, strong) NSString *fileURL;
@property (nonatomic, readonly, assign) uint64_t fileSize;
@property (nonatomic, readonly, assign) uint64_t duration;

@end

@interface CHAudioMsgCellContentView : CHBubbleMsgCellContentView<CHAudioMsgCellConfiguration *>

@property (nonatomic, readonly, strong) CHImageView *ctrlIcon;
@property (nonatomic, readonly, strong) CHLabel *durationLabel;
@property (nonatomic, readonly, strong) CHLabel *statusLabel;
@property (nonatomic, readonly, strong) CHProgressView *audioTrackView;
@property (nonatomic, readonly, strong) NSNumber *duration;
@property (nonatomic, nullable, readonly, strong) NSURL *localFileURL;

@end

@interface CHAudioMsgCellContentView () <CHWebAudioItem, CHAudioPlayerDelegate>
@end

@implementation CHAudioMsgCellContentView

- (void)dealloc {
    [CHAudioPlayer.shared removeDelegate:self];
}

- (void)setupViews {
    [super setupViews];

    CHTheme *theme = CHTheme.shared;
    
    CHImageView *ctrlIcon = [CHImageView new];
    [self.bubbleView addSubview:(_ctrlIcon = ctrlIcon)];
    ctrlIcon.contentMode = UIViewContentModeScaleAspectFit;

    CHLabel *durationLabel = [CHLabel new];
    [self.bubbleView addSubview:(_durationLabel = durationLabel)];
    durationLabel.backgroundColor = CHColor.clearColor;
    durationLabel.textColor = theme.labelColor;
    durationLabel.numberOfLines = 1;
    durationLabel.font = theme.messageSmallDigitalFont;

    CHLabel *statusLabel = [CHLabel new];
    [self.bubbleView addSubview:(_statusLabel = statusLabel)];
    statusLabel.textAlignment = NSTextAlignmentRight;
    statusLabel.backgroundColor = CHColor.clearColor;
    statusLabel.textColor = theme.minorLabelColor;
    statusLabel.numberOfLines = 1;
    statusLabel.font = theme.messageSmallDigitalFont;
    
    CHProgressView *audioTrackView = [[CHProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    [self.bubbleView addSubview:(_audioTrackView = audioTrackView)];
    audioTrackView.tintColor = theme.labelColor;
    audioTrackView.trackTintColor = theme.lightLabelColor;

    [CHAudioPlayer.shared addDelegate:self];
}

- (void)applyConfiguration:(CHAudioMsgCellConfiguration *)configuration {
    [super applyConfiguration:configuration];
    
    CGSize size = configuration.bubbleRect.size;
    self.ctrlIcon.frame = CGRectMake(16, (size.height - 30)/2, 30, 30);
    CGFloat offset = CGRectGetMaxX(self.ctrlIcon.frame) + 10;
    CGRect frame = CGRectMake(offset, size.height - 16, size.width - offset - 10, 10);
    self.durationLabel.frame = frame;
    self.statusLabel.frame = frame;
    frame.size.height = 1;
    frame.origin.y = (size.height - 10)/2;
    self.audioTrackView.frame = frame;
    self.audioTrackView.progress = 0;
    
    _duration = @(0);
    _localFileURL = nil;
    self.durationLabel.text = @"";
    self.statusLabel.text = @"";
    [self updatePlayStatus];
    [CHLogic.shared.webAudioManager loadAudioURL:configuration.fileURL toItem:self expectedSize:configuration.fileSize];
}

- (NSArray<CHMenuItem *> *)menuActions {
    NSMutableArray *items = [NSMutableArray new];
    if (self.localFileURL != nil) {
        [items addObject:[[CHMenuItem alloc]initWithTitle:@"Share".localized action:@selector(actionShare:)]];
    }
    [items addObjectsFromArray:super.menuActions];
    return items;
}

#pragma mark - CHWebAudioItem
- (void)webAudioUpdated:(nullable NSURL *)item fileURL:(nullable NSString *)fileURL {
    CHAudioMsgCellConfiguration *configuration = (CHAudioMsgCellConfiguration *)self.configuration;
    if ([configuration.fileURL isEqualToString:fileURL]) {
        _localFileURL = item;
        if (item == nil) {
            self.statusLabel.text = @"Download failed and click to retry".localized;
            self.durationLabel.text = @"";
        } else {
            self.statusLabel.text = [@(configuration.fileSize ?: self.localFileURL.fileSize) formatFileSize];
            if (configuration.duration > 0) {
                _duration = @(configuration.duration);
            } else {
                _duration = [CHLogic.shared.webAudioManager loadLocalURLDuration:self.localFileURL];
            }
            self.durationLabel.text = [self.duration formatDuration];
        }
        [self updatePlayStatus];
    }
}

- (void)webAudioProgress:(double)progress fileURL:(nullable NSString *)fileURL {
    CHAudioMsgCellConfiguration *configuration = (CHAudioMsgCellConfiguration *)self.configuration;
    if ([configuration.fileURL isEqualToString:fileURL]) {
        self.statusLabel.text = [NSString stringWithFormat:@"Downloading %6.02f%%".localized, progress * 100];
        self.durationLabel.text = @"";
    }
}

#pragma mark - CHAudioPlayerDelegate
- (void)audioPlayStatusChanged:(CHAudioPlayer *)audioPlayer {
    [self updatePlayStatus];
}

- (void)audioPlayTrackChanged:(CHAudioPlayer *)audioPlayer {
    [self updatePlayTrack];
}

#pragma mark - Action Methods
- (void)actionShare:(id)sender {
    if (self.localFileURL != nil) {
        NSURL *url = [NSFileManager.defaultManager URLLinkForFile:self.localFileURL withName:@"audio.mp3"];
        [CHRouter.shared showShareItem:@[url] sender:self.contentView handler:nil];
    }
}

- (void)actionClicked:(CHTapGestureRecognizer *)sender {
    if (self.localFileURL != nil) {
        CHAudioPlayer *audioPlayer = CHAudioPlayer.shared;
        if ([self.localFileURL isEqual:audioPlayer.currentURL] && audioPlayer.isPlaying) {
            [audioPlayer pause];
        } else {
            [audioPlayer playWithURL:self.localFileURL];
        }
    } else {
        CHWebAudioManager *webAudioManager = CHLogic.shared.webAudioManager;
        self.statusLabel.text = @"";
        CHAudioMsgCellConfiguration *configuration = (CHAudioMsgCellConfiguration *)self.configuration;
        [webAudioManager resetFileURLFailed:configuration.fileURL];
        [webAudioManager loadAudioURL:configuration.fileURL toItem:self expectedSize:configuration.fileSize];
    }
}

#pragma mark - Private Methods
- (void)updatePlayStatus {
    CHTheme *theme = CHTheme.shared;
    if (self.localFileURL == nil) {
        self.ctrlIcon.tintColor = theme.minorLabelColor;
        self.ctrlIcon.image = [CHImage systemImageNamed:@"music.note"];
        self.audioTrackView.progress = 0;
    } else {
        self.ctrlIcon.tintColor = theme.labelColor;
        CHAudioPlayer *audioPlayer = CHAudioPlayer.shared;
        if ([self.localFileURL isEqual:audioPlayer.currentURL] && audioPlayer.isPlaying) {
            self.ctrlIcon.image = [CHImage systemImageNamed:@"pause.circle"];
        } else {
            self.ctrlIcon.image = [CHImage systemImageNamed:@"play.circle"];
        }
        [self updatePlayTrack];
    }
}

- (void)updatePlayTrack {
    if (self.localFileURL != nil) {
        CHAudioPlayer *audioPlayer = CHAudioPlayer.shared;
        if ([self.localFileURL isEqual:audioPlayer.currentURL]) {
            double scale = audioPlayer.audioTrack.doubleValue;
            self.audioTrackView.progress = scale;
            self.durationLabel.text = [@(self.duration.doubleValue * (1 - scale)) formatDuration];
        } else {
            self.audioTrackView.progress = 0;
            self.durationLabel.text = [self.duration formatDuration];
        }
    }
}


@end

@implementation CHAudioMsgCellConfiguration

+ (instancetype)cellConfiguration:(CHMessageModel *)model {
    return [[self.class alloc] initWithMID:model.mid fileURL:model.fileURL fileSize:model.fileSize duration:model.duration bubbleRect:CGRectZero];
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [[self.class allocWithZone:zone] initWithMID:self.mid fileURL:self.fileURL fileSize:self.fileSize duration:self.duration bubbleRect:self.bubbleRect];
}

- (instancetype)initWithMID:(NSString *)mid fileURL:(NSString * _Nullable)fileURL fileSize:(uint64_t)fileSize duration:(uint64_t)duration bubbleRect:(CGRect)bubbleRect {
    if (self = [super initWithMID:mid bubbleRect:bubbleRect]) {
        _fileURL = fileURL;
        _fileSize = fileSize;
        _duration = duration;
    }
    return self;
}

- (__kindof CHView<CHContentView> *)makeContentView {
    return [[CHAudioMsgCellContentView alloc] initWithConfiguration:self];
}

- (CGSize)calcContentSize:(CGSize)size {
    return CGSizeMake(MIN(size.width, 300), 60);
}


@end
