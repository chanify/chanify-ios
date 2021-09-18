//
//  CHListContentConfiguration.h
//  OSX
//
//  Created by WizJin on 2021/9/18.
//

#import "CHCollectionViewCell.h"

NS_ASSUME_NONNULL_BEGIN

#define CHListContentTextAlignmentLeft      NSTextAlignmentLeft
#define CHListContentTextAlignmentRight     NSTextAlignmentRight
#define CHListContentTextAlignmentCenter    NSTextAlignmentCenter

@interface CHContentTextProperties : NSObject

@property (nonatomic, assign) NSTextAlignment alignment;
@property (nonatomic, nullable, strong) NSColor *color;
@property (nonatomic, nullable, strong) NSFont *font;

@end


@interface CHListContentConfiguration : NSObject<CHContentConfiguration>

@property (nonatomic, nullable, strong) NSImage *image;
@property (nonatomic, nullable, strong) NSString *text;
@property (nonatomic, nullable, strong) NSString *secondaryText;
@property (nonatomic, nullable, strong) CHContentTextProperties *textProperties;
@property (nonatomic, nullable, strong) CHContentTextProperties *secondaryTextProperties;

+ (instancetype)valueCellConfiguration;
+ (instancetype)cellConfiguration;

- (__kindof NSView<CHContentView> *)makeContentView;
- (instancetype)updatedConfigurationForState:(id<CHConfigurationState>)state;

@end

NS_ASSUME_NONNULL_END
