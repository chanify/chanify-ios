//
//  CHAudioMsgCellConfiguration.m
//  iOS
//
//  Created by WizJin on 2021/5/27.
//

#import "CHAudioMsgCellConfiguration.h"
#import "CHTheme.h"

@interface CHAudioMsgCellConfiguration ()

@property (nonatomic, readonly, strong) NSString *fileURL;
@property (nonatomic, readonly, assign) uint64_t duration;

@end

@interface CHAudioMsgCellContentView : CHBubbleMsgCellContentView<CHAudioMsgCellConfiguration *>

@property (nonatomic, readonly, strong) UILabel *durationLabel;
@property (nonatomic, nullable, readonly, strong) NSURL *localFileURL;

@end

@implementation CHAudioMsgCellContentView

- (void)setupViews {
    [super setupViews];
    
    CHTheme *theme = CHTheme.shared;
    
    UILabel *durationLabel = [UILabel new];
    [self.bubbleView addSubview:(_durationLabel = durationLabel)];
    durationLabel.textAlignment = NSTextAlignmentRight;
    durationLabel.backgroundColor = UIColor.clearColor;
    durationLabel.textColor = theme.minorLabelColor;
    durationLabel.numberOfLines = 1;
    durationLabel.font = [UIFont monospacedSystemFontOfSize:8 weight:UIFontWeightRegular];
}

- (void)applyConfiguration:(CHAudioMsgCellConfiguration *)configuration {
    [super applyConfiguration:configuration];
}

@end

@implementation CHAudioMsgCellConfiguration

+ (instancetype)cellConfiguration:(CHMessageModel *)model {
    return [[self.class alloc] initWithMID:model.mid fileURL:model.fileURL duration:model.duration bubbleRect:CGRectZero];
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [[self.class allocWithZone:zone] initWithMID:self.mid fileURL:self.fileURL duration:self.duration bubbleRect:self.bubbleRect];
}

- (instancetype)initWithMID:(NSString *)mid fileURL:(NSString * _Nullable)fileURL duration:(uint64_t)duration bubbleRect:(CGRect)bubbleRect {
    if (self = [super initWithMID:mid bubbleRect:bubbleRect]) {
        _fileURL = fileURL;
        _duration = duration;
    }
    return self;
}

- (__kindof UIView<UIContentView> *)makeContentView {
    return [[CHAudioMsgCellContentView alloc] initWithConfiguration:self];
}

- (CGSize)calcContentSize:(CGSize)size {
    return CGSizeMake(MIN(size.width, 300), 40);
}


@end
