//
//  CHCollectionViewCell.h
//  OSX
//
//  Created by WizJin on 2021/6/7.
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CHContentConfiguration;
@protocol CHConfigurationState
@end

@protocol CHContentView <NSObject>
@property (nonatomic, copy) id<CHContentConfiguration> configuration;
@end

@protocol CHContentConfiguration <NSObject, NSCopying>
- (__kindof NSView<CHContentView> *)makeContentView;
- (instancetype)updatedConfigurationForState:(id<CHConfigurationState>)state;
@end

@interface CHCellConfigurationState : NSObject<CHConfigurationState>

- (BOOL)isSelected;

@end

@interface CHCollectionViewCell : NSCollectionViewItem

@property (nonatomic, nullable, strong) NSView *contentView;
@property (nonatomic, nullable, strong) id<CHContentConfiguration> contentConfiguration;

- (void)updateConfigurationUsingState:(CHCellConfigurationState *)state;

@end

NS_ASSUME_NONNULL_END
