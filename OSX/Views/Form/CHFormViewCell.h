//
//  CHFormViewCell.h
//  OSX
//
//  Created by WizJin on 2021/9/18.
//

#import "CHCollectionViewCell.h"
#import "CHListContentView.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CHFormViewCellAccessoryType) {
    CHFormViewCellAccessoryNone,
    CHFormViewCellAccessoryDisclosureIndicator,
};

@class CHFormItem;

@interface CHFormViewCell : CHCollectionViewCell

@property (nonatomic, assign) CHFormViewCellAccessoryType accessoryType;
@property (nonatomic, nullable, strong) NSView *accessoryView;

- (void)setItem:(CHFormItem *)item;


@end

NS_ASSUME_NONNULL_END
