//
//  CHNodeCellView.h
//  OSX
//
//  Created by WizJin on 2021/9/6.
//

#import "CHUI.h"
#import "CHNodeModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHNodeCellView : NSCollectionViewItem

@property (nonatomic, nullable, strong) CHNodeModel *model;


@end

NS_ASSUME_NONNULL_END
