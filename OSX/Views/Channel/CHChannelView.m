//
//  CHChannelView.m
//  OSX
//
//  Created by WizJin on 2021/6/1.
//

#import "CHChannelView.h"
#import <Masonry/Masonry.h>
#import "CHUserDataSource.h"
#import "CHMsgsDataSource.h"
#import "CHCollectionView.h"
#import "CHChannelModel.h"
#import "CHMessageModel.h"
#import "CHScrollView.h"
#import "CHLogic.h"
#import "CHTheme.h"

#define kCHChannelViewBottomMargin  30

@interface CHChannelView () <NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout, CHScrollViewDelegate, CHLogicDelegate>

@property (nonatomic, readonly, strong) CHLabel *titleLabel;
@property (nonatomic, readonly, strong) CHScrollView *scrollView;
@property (nonatomic, readonly, strong) CHCollectionView *listView;
@property (nonatomic, readonly, strong) CHMsgsDataSource *dataSource;

@end

@implementation CHChannelView

- (instancetype)initWithCID:(NSString *)cid {
    if (self = [super initWithFrame:NSZeroRect]) {
        _cid = cid;
        CHChannelModel *model = [CHLogic.shared.userDataSource channelWithCID:cid];

        CHTheme *theme = CHTheme.shared;
        
        self.backgroundColor = theme.selectedCellBackgroundColor;
        
        CHLabel *titleLabel = [CHLabel new];
        [self addSubview:(_titleLabel = titleLabel)];
        [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self);
            make.left.equalTo(self).offset(16);
            make.height.mas_equalTo(58);
        }];
        titleLabel.font = [CHFont systemFontOfSize:16];
        titleLabel.text = model.title;
        
        NSCollectionViewFlowLayout *layout = [NSCollectionViewFlowLayout new];
        layout.minimumLineSpacing = 16;
        CHCollectionView *listView = [[CHCollectionView alloc] initWithLayout:layout];
        _listView = listView;
        listView.backgroundColor = theme.backgroundColor;
        listView.allowsMultipleSelection = NO;
        listView.selectable = NO;
        listView.delegate = self;
        
        CHScrollView *scrollView = [CHScrollView new];
        [self addSubview:(_scrollView = scrollView)];
        [scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.bottom.equalTo(self);
            make.top.equalTo(titleLabel.mas_bottom);
        }];
        scrollView.contentInsets = NSEdgeInsetsMake(0, 0, kCHChannelViewBottomMargin, 0);
        scrollView.scrollerInsets = NSEdgeInsetsMake(0, 0, -kCHChannelViewBottomMargin, 0);
        scrollView.backgroundColor = theme.backgroundColor;
        scrollView.automaticallyAdjustsContentInsets = NO;
        scrollView.documentView = listView;
        scrollView.hasVerticalScroller = YES;
        scrollView.delegate = self;

        _dataSource = [CHMsgsDataSource dataSourceWithCollectionView:listView channelID:cid];
        self.dataSource.scroller = scrollView;
        
        [CHLogic.shared addDelegate:self];
        
        [self.dataSource reset:NO];
    }
    return self;
}

- (void)dealloc {
    [CHLogic.shared removeDelegate:self];
}

- (void)viewDidAppear {
    [CHLogic.shared addReadChannel:self.cid];
}

- (void)viewDidDisappear {
    [CHLogic.shared removeReadChannel:self.cid];
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

#pragma mark - CHScrollViewDelegate
- (void)scrollViewDidScroll:(CHScrollView *)scrollView {
    if (scrollView.documentVisibleRect.origin.y <= 0) {
        [self.dataSource scrollViewDidScroll];
    }
}

#pragma mark - CHLogicDelegate
- (void)logicMessagesUpdated:(NSArray<NSString *> *)mids {
    // TODO: Fix recive unordered messages.
    [self.dataSource loadLatestMessage:YES];
}

- (void)logicMessageDeleted:(CHMessageModel *)model {
    [self.dataSource deleteMessage:model animated:YES];
}

- (void)logicMessagesDeleted:(NSArray<NSString *> *)mids {
    [self.dataSource deleteMessages:mids animated:YES];
}

- (void)logicMessagesCleared:(NSString *)cid {
    if ([self.cid isEqualToString:cid]) {
        [self.dataSource reset:YES];
    }
}


@end
