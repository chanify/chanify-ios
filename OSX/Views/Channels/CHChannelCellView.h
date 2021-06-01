//
//  CHChannelCellView.h
//  OSX
//
//  Created by WizJin on 2021/6/1.
//

#import <AppKit/AppKit.h>
#import "CHChannelModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHChannelCellView : NSCollectionViewItem

@property (nonatomic, nullable, strong) CHChannelModel *model;


@end

NS_ASSUME_NONNULL_END
