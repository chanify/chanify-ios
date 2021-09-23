//
//  CHCollectionViewCellRegistration.h
//  OSX
//
//  Created by WizJin on 2021/6/7.
//

#import <AppKit/AppKit.h>
#import "CHCollectionViewCell.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^NSCollectionViewCellRegistrationConfigurationHandler)(__kindof NSCollectionViewItem * _Nonnull cell, NSIndexPath * _Nonnull indexPath, id _Nonnull item);

@interface CHCollectionViewCellRegistration : NSObject

@property (nonatomic, readonly, strong) NSString *itemIdentifier;
@property (nonatomic, readonly, strong) NSCollectionViewCellRegistrationConfigurationHandler configurationHandler;

+ (instancetype)registrationWithCellClass:(Class)cellClass configurationHandler:(NSCollectionViewCellRegistrationConfigurationHandler)configurationHandler;
- (void)registerCollectionView:(NSCollectionView *)collectionView;


@end

NS_ASSUME_NONNULL_END
