//
//  CHAudioMsgCellConfiguration.m
//  iOS
//
//  Created by WizJin on 2021/5/27.
//

#import "CHAudioMsgCellConfiguration.h"
#import "CHWebAudioManager.h"
#import "CHLogic+iOS.h"
#import "CHRouter.h"
#import "CHTheme.h"

@interface CHAudioMsgCellConfiguration ()

@property (nonatomic, readonly, strong) NSString *fileURL;
@property (nonatomic, readonly, assign) uint64_t fileSize;
@property (nonatomic, readonly, assign) uint64_t duration;

@end

@interface CHAudioMsgCellContentView : CHBubbleMsgCellContentView<CHAudioMsgCellConfiguration *>

@property (nonatomic, readonly, strong) UIImageView *ctrlIcon;
@property (nonatomic, readonly, strong) UILabel *statusLabel;
@property (nonatomic, nullable, readonly, strong) NSURL *localFileURL;

@end

@interface CHAudioMsgCellContentView () <CHWebAudioItem>
@end

@implementation CHAudioMsgCellContentView

- (void)setupViews {
    [super setupViews];

    CHTheme *theme = CHTheme.shared;
    
    UIImageView *ctrlIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"play.circle"]];
    [self.bubbleView addSubview:(_ctrlIcon = ctrlIcon)];
    ctrlIcon.tintColor = theme.labelColor;

    UILabel *statusLabel = [UILabel new];
    [self.bubbleView addSubview:(_statusLabel = statusLabel)];
    statusLabel.textAlignment = NSTextAlignmentRight;
    statusLabel.backgroundColor = UIColor.clearColor;
    statusLabel.textColor = theme.minorLabelColor;
    statusLabel.numberOfLines = 1;
    statusLabel.font = [UIFont monospacedSystemFontOfSize:8 weight:UIFontWeightRegular];
}

- (void)applyConfiguration:(CHAudioMsgCellConfiguration *)configuration {
    [super applyConfiguration:configuration];
    
    CGSize size = configuration.bubbleRect.size;
    self.ctrlIcon.frame = CGRectMake(16, (size.height - 30)/2, 30, 30);
    CGFloat offset = CGRectGetMaxX(self.ctrlIcon.frame);
    self.statusLabel.frame = CGRectMake(offset, size.height - 16, size.width - offset - 10, 10);
    
    _localFileURL = nil;
    self.statusLabel.text = @"";
    [CHLogic.shared.webAudioManager loadAudioURL:configuration.fileURL toItem:self expectedSize:configuration.fileSize];
}

- (NSArray<UIMenuItem *> *)menuActions {
    NSMutableArray *items = [NSMutableArray new];
    if (self.localFileURL != nil) {
        [items addObject:[[UIMenuItem alloc]initWithTitle:@"Share".localized action:@selector(actionShare:)]];
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
        } else {
            self.statusLabel.text = [@(configuration.fileSize ?: self.localFileURL.fileSize) formatFileSize];
        }
    }
}

- (void)webAudioProgress:(double)progress fileURL:(nullable NSString *)fileURL {
    CHAudioMsgCellConfiguration *configuration = (CHAudioMsgCellConfiguration *)self.configuration;
    if ([configuration.fileURL isEqualToString:fileURL]) {
        self.statusLabel.text = [NSString stringWithFormat:@"Downloading %6.02f%%".localized, progress * 100];
    }
}

#pragma mark - Action Methods
- (void)actionShare:(id)sender {
    if (self.localFileURL != nil) {
        NSURL *url = [NSFileManager.defaultManager URLLinkForFile:self.localFileURL withName:@"audio.mp3"];
        [CHRouter.shared showShareItem:@[url] sender:self.contentView handler:nil];
    }
}

- (void)actionClicked:(UITapGestureRecognizer *)sender {

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

- (__kindof UIView<UIContentView> *)makeContentView {
    return [[CHAudioMsgCellContentView alloc] initWithConfiguration:self];
}

- (CGSize)calcContentSize:(CGSize)size {
    return CGSizeMake(MIN(size.width, 300), 60);
}


@end
