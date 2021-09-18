//
//  CHCollectionViewCellRegistration.m
//  OSX
//
//  Created by WizJin on 2021/6/7.
//

#import "CHCollectionViewCellRegistration.h"

@implementation CHCollectionViewCellRegistration

+ (instancetype)registrationWithCellClass:(Class)cellClass configurationHandler:(NSCollectionViewCellRegistrationConfigurationHandler)configurationHandler {
    return [[self.class alloc] initWithClass:cellClass configurationHandler:configurationHandler];
}

- (instancetype)initWithClass:(Class)cellClass configurationHandler:(NSCollectionViewCellRegistrationConfigurationHandler)configurationHandler {
    if (self = [super init]) {
        _itemIdentifier = NSStringFromClass(cellClass);
        _configurationHandler = configurationHandler;
    }
    return self;
}

- (void)registerCollectionView:(NSCollectionView *)collectionView {
    [collectionView registerClass:NSClassFromString(self.itemIdentifier) forItemWithIdentifier:self.itemIdentifier];
}


@end
