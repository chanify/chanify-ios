//
//  CHChannelView.m
//  OSX
//
//  Created by WizJin on 2021/6/1.
//

#import "CHChannelView.h"
#import <Masonry/Masonry.h>
#import "CHMsgsDataSource.h"
#import "CHCollectionView.h"
#import "CHLogic+OSX.h"
#import "CHTheme.h"

@interface CHChannelView () <NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout, CHLogicDelegate>

@property (nonatomic, readonly, strong) CHCollectionView *listView;
@property (nonatomic, readonly, strong) CHMsgsDataSource *dataSource;

@end

@implementation CHChannelView

- (instancetype)initWithCID:(NSString *)cid {
    if (self = [super initWithFrame:NSZeroRect]) {
        _cid = cid;
        
        CHTheme *theme = CHTheme.shared;
        
        NSCollectionViewFlowLayout *layout = [NSCollectionViewFlowLayout new];
        layout.minimumLineSpacing = 16;
        CHCollectionView *listView = [[CHCollectionView alloc] initWithLayout:layout];
        _listView = listView;
        listView.backgroundColor = theme.backgroundColor;
        listView.allowsMultipleSelection = NO;
        listView.selectable = NO;
        listView.delegate = self;

        self.documentView = listView;
        self.hasVerticalScroller = YES;
        self.backgroundColor = theme.backgroundColor;
        
        _dataSource = [CHMsgsDataSource dataSourceWithCollectionView:listView channelID:cid];
        
        [CHLogic.shared addDelegate:self];
        
        [self.dataSource reset:NO];
    }
    return self;
}

- (void)dealloc {
    [CHLogic.shared removeDelegate:self];
}

#pragma mark - NSCollectionViewDelegate
- (void)collectionView:(NSCollectionView *)collectionView didSelectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths {
    [self.dataSource selectItemWithIndexPaths:indexPaths];
}

#pragma mark - NSCollectionViewDelegateFlowLayout
- (NSSize)collectionView:(NSCollectionView *)collectionView layout:(NSCollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self.dataSource sizeForItemAtIndexPath:indexPath];
}

#pragma mark - CHLogicDelegate


@end
