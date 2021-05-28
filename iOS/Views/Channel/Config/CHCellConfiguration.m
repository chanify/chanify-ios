//
//  CHCellConfiguration.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHCellConfiguration.h"
#import "CHMessageCellView.h"
#import "CHDateCellConfiguration.h"
#import "CHTextMsgCellConfiguration.h"
#import "CHActionMsgCellConfiguration.h"
#import "CHLinkMsgCellConfiguration.h"
#import "CHFileMsgCellConfiguration.h"
#import "CHImageMsgCellConfiguration.h"
#import "CHAudioMsgCellConfiguration.h"
#import "CHUnknownMsgCellConfiguration.h"

@implementation CHCellConfiguration

+ (instancetype)cellConfiguration:(CHMessageModel *)model {
    switch (model.type) {
        case CHMessageTypeText:
            return [CHTextMsgCellConfiguration cellConfiguration:model];
        case CHMessageTypeLink:
            return [CHLinkMsgCellConfiguration cellConfiguration:model];
        case CHMessageTypeFile:
            return [CHFileMsgCellConfiguration cellConfiguration:model];
        case CHMessageTypeImage:
            return [CHImageMsgCellConfiguration cellConfiguration:model];
        case CHMessageTypeAudio:
            return [CHAudioMsgCellConfiguration cellConfiguration:model];
        case CHMessageTypeAction:
            return [CHActionMsgCellConfiguration cellConfiguration:model];
        default:
            break;
    }
    return [CHUnknownMsgCellConfiguration cellConfiguration:model];;
}

+ (NSDictionary<NSString *, UICollectionViewCellRegistration *> *)cellRegistrations {
#define CellConfiguration(_clz) NSStringFromClass(_clz.class): cellRegistration(_clz.class)
    return @{
        CellConfiguration(CHDateCellConfiguration),
        CellConfiguration(CHTextMsgCellConfiguration),
        CellConfiguration(CHActionMsgCellConfiguration),
        CellConfiguration(CHLinkMsgCellConfiguration),
        CellConfiguration(CHFileMsgCellConfiguration),
        CellConfiguration(CHImageMsgCellConfiguration),
        CellConfiguration(CHAudioMsgCellConfiguration),
        CellConfiguration(CHUnknownMsgCellConfiguration),
    };
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [[self.class allocWithZone:zone] initWithMID:self.mid];
}

- (nonnull __kindof UIView<UIContentView> *)makeContentView {
    return nil;
}

- (nonnull instancetype)updatedConfigurationForState:(nonnull id<UIConfigurationState>)state {
    return self;
}

- (instancetype)initWithMID:(NSString *)mid {
    if (self = [super init]) {
        _mid = mid;
    }
    return self;
}

- (nullable NSString *)mediaThumbnailURL {
    return nil;
}

- (NSDate *)date {
    return [NSDate dateFromMID:self.mid];
}

- (BOOL)isEqual:(CHCellConfiguration *)rhs {
    return [self.mid isEqualToString:rhs.mid] && self.class == rhs.class;
}

- (NSUInteger)hash {
    return self.mid.hash;
}

- (void)setNeedRecalcLayout {
}

- (CGSize)calcSize:(CGSize)size {
    return size;
}

inline static UICollectionViewCellRegistration *cellRegistration(Class clz) {
    return [UICollectionViewCellRegistration registrationWithCellClass:CHMessageCellView.class configurationHandler:^(UICollectionViewCell *cell, NSIndexPath *indexPath, CHCellConfiguration *item) {
        if ([item isKindOfClass:clz]) {
            cell.contentConfiguration = item;
        }
    }];
}


@end
