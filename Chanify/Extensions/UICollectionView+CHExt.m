//
//  UICollectionView+CHExt.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "UICollectionView+CHExt.h"
#import <UIKit/UICollectionViewCompositionalLayout.h>

@implementation UICollectionView (CHExt)

+ (instancetype)collectionListViewWithHeight:(CGFloat)height {
    NSCollectionLayoutItem *item = [NSCollectionLayoutItem itemWithLayoutSize:[NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1] heightDimension:[NSCollectionLayoutDimension absoluteDimension:height]]];
    NSCollectionLayoutGroup *group = [NSCollectionLayoutGroup verticalGroupWithLayoutSize:[NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1] heightDimension:[NSCollectionLayoutDimension absoluteDimension:height + 1]] subitems:@[item]];
    group.interItemSpacing = [NSCollectionLayoutSpacing fixedSpacing:1];
    NSCollectionLayoutSection *section = [NSCollectionLayoutSection sectionWithGroup:group];
    section.contentInsets = NSDirectionalEdgeInsetsMake(1, 0, 0, 0);
    UICollectionViewCompositionalLayout *layout = [[UICollectionViewCompositionalLayout alloc] initWithSection:section];
    return [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
}


@end
