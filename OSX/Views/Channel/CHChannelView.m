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
#import "CHMessageModel.h"
#import "CHLogic+OSX.h"
#import "CHTheme.h"

#define kCHChannelViewBottomMargin  30

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
        
        self.contentInsets = NSEdgeInsetsMake(0, 0, kCHChannelViewBottomMargin, 0);
        self.scrollerInsets = NSEdgeInsetsMake(0, 0, -kCHChannelViewBottomMargin, 0);
        self.automaticallyAdjustsContentInsets = NO;
        self.documentView = listView;
        self.hasVerticalScroller = YES;
        self.backgroundColor = theme.backgroundColor;

        _dataSource = [CHMsgsDataSource dataSourceWithCollectionView:listView channelID:cid];
        self.dataSource.scroller = self;
        
        [CHLogic.shared addDelegate:self];
        
        [self.dataSource reset:NO];
    }
    return self;
}

- (void)dealloc {
    [CHLogic.shared removeDelegate:self];
}

- (void)scrollWheel:(NSEvent *)theEvent {
    [super scrollWheel:theEvent];
    [self.dataSource scrollViewDidScroll];
}

#pragma mark - NSCollectionViewDelegate
- (void)collectionView:(NSCollectionView *)collectionView didSelectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths {
    [self.dataSource selectItemWithIndexPaths:indexPaths];
}

#pragma mark - NSCollectionViewDelegateFlowLayout
- (NSSize)collectionView:(NSCollectionView *)collectionView layout:(NSCollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self.dataSource sizeForItemAtIndexPath:indexPath];
}

- (NSSize)collectionView:(NSCollectionView *)collectionView layout:(NSCollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return [self.dataSource sizeForHeaderInSection:section];
}

#pragma mark - CHLogicDelegate
- (void)logicChannelUpdated:(NSString *)cid {
    //[self updateChannel:cid];
}

- (void)logicMessagesUpdated:(NSArray<NSString *> *)mids {
    // TODO: Fix recive unordered messages.
    [self.dataSource loadLatestMessage:YES];
}

- (void)logicMessageDeleted:(CHMessageModel *)model {
    //[self.dataSource deleteMessage:model animated:YES];
}

- (void)logicMessagesDeleted:(NSArray<NSString *> *)mids {
    //[self.dataSource deleteMessages:mids animated:YES];
}

- (void)logicMessagesCleared:(NSString *)cid {
    if ([self.cid isEqualToString:cid]) {
        [self.dataSource reset:YES];
    }
}

- (void)logicMessagesUnreadChanged:(NSNumber *)unread {
    //[self updateUnreadBadge:unread.integerValue];
}


@end
