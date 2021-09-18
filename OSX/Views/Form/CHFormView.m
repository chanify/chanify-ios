//
//  CHFormView.m
//  OSX
//
//  Created by WizJin on 2021/9/18.
//

#import "CHFormView.h"
#import "CHScrollView.h"
#import "CHCollectionView.h"
#import "CHTheme.h"

@interface CHFormView () <NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout>

@property (nonatomic, readonly, strong) CHScrollView *scrollView;
@property (nonatomic, readonly, strong) CHCollectionView *listView;

@end

@implementation CHFormView

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {        
        CHTheme *theme = CHTheme.shared;

        NSCollectionViewFlowLayout *layout = [NSCollectionViewFlowLayout new];
        layout.minimumLineSpacing = 16;
        CHCollectionView *listView = [[CHCollectionView alloc] initWithLayout:layout];
        _listView = listView;
        listView.backgroundColor = theme.groupedBackgroundColor;
        listView.allowsMultipleSelection = NO;
        listView.selectable = NO;
        listView.delegate = self;
        
        CHScrollView *scrollView = [CHScrollView new];
        [self addSubview:(_scrollView = scrollView)];
        scrollView.backgroundColor = theme.groupedBackgroundColor;
        scrollView.automaticallyAdjustsContentInsets = NO;
        scrollView.documentView = listView;
        scrollView.hasVerticalScroller = YES;
        scrollView.hasHorizontalScroller = NO;
    }
    return self;
}

#pragma mark - NSCollectionViewDelegate
- (void)collectionView:(NSCollectionView *)collectionView didSelectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths {
}

#pragma mark - NSCollectionViewDelegateFlowLayout
- (NSSize)collectionView:(NSCollectionView *)collectionView layout:(NSCollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return NSMakeSize(collectionView.bounds.size.width, 30);
}


@end
