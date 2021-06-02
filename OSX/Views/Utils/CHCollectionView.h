//
//  CHCollectionView.h
//  OSX
//
//  Created by WizJin on 2021/6/2.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHCollectionView : NSCollectionView

- (instancetype)initWithLayout:(NSCollectionViewFlowLayout *)layout;
- (void)setBackgroundColor:(NSColor *)color;


@end

NS_ASSUME_NONNULL_END
