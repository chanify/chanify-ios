//
//  CHChannelViewPage.m
//  OSX
//
//  Created by WizJin on 2021/6/1.
//

#import "CHChannelViewPage.h"
#import "CHCollectionView.h"
#import "CHUserDataSource.h"
#import "CHMsgsDataSource.h"
#import "CHChannelModel.h"
#import "CHMessageModel.h"
#import "CHScrollView.h"
#import "CHRouter.h"
#import "CHLogic.h"
#import "CHTheme.h"

#define kCHChannelViewBottomMargin  30

@interface CHChannelViewPage () <NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout, CHScrollViewDelegate, CHLogicDelegate>

@property (nonatomic, readonly, strong) CHChannelModel *model;
@property (nonatomic, readonly, strong) CHScrollView *scrollView;
@property (nonatomic, readonly, strong) CHCollectionView *listView;
@property (nonatomic, readonly, strong) CHMsgsDataSource *dataSource;

@end

@implementation CHChannelViewPage

- (instancetype)initWithParameters:(NSDictionary *)params {
    if (self = [super initWithFrame:NSZeroRect]) {
        _model = [CHLogic.shared.userDataSource channelWithCID:[params valueForKey:@"cid"]];

        CHTheme *theme = CHTheme.shared;
        
        self.title = self.model.title;
        self.backgroundColor = theme.backgroundColor;
        self.rightBarButtonItem = [CHBarButtonItem itemWithTitle:@"⋯" target:self action:@selector(actionInfo:)];

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
        scrollView.contentInsets = NSEdgeInsetsMake(0, 0, kCHChannelViewBottomMargin, 0);
        scrollView.scrollerInsets = NSEdgeInsetsMake(0, 0, -kCHChannelViewBottomMargin, 0);
        scrollView.backgroundColor = theme.groupedBackgroundColor;
        scrollView.automaticallyAdjustsContentInsets = NO;
        scrollView.documentView = listView;
        scrollView.hasVerticalScroller = YES;
        scrollView.hasHorizontalScroller = NO;
        scrollView.delegate = self;

        _dataSource = [CHMsgsDataSource dataSourceWithCollectionView:listView channelID:self.model.cid];
        self.dataSource.scroller = scrollView;
        
        [CHLogic.shared addDelegate:self];
        
        [self.dataSource reset:NO];
    }
    return self;
}

- (void)dealloc {
    [CHLogic.shared removeDelegate:self];
}

- (void)mouseDown:(NSEvent *)event {
    [self.dataSource clearActivedCellItem];
}

- (BOOL)isEqualWithParameters:(NSDictionary *)params {
    return [self.model.cid isEqual:[params valueForKey:@"cid"]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [CHLogic.shared addReadChannel:self.model.cid];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [CHLogic.shared removeReadChannel:self.model.cid];
}

- (void)layout {
    CHScrollView *scroller = self.scrollView;
    CGPoint offset = scroller.documentVisibleRect.origin;
    CGFloat height = NSHeight(scroller.documentVisibleRect);
    CGFloat allH = NSHeight(scroller.documentView.bounds);
    CGFloat insets = scroller.contentInsets.top + scroller.contentInsets.bottom;
    [super layout];
    scroller.frame = self.bounds;
    if (offset.y + height >= allH + insets) {
        offset.y += height - NSHeight(scroller.documentVisibleRect);
        [scroller.documentView scrollPoint:offset];
    }
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
    if ([self.model.cid isEqualToString:cid]) {
        [self.dataSource reset:YES];
    }
}

#pragma mark - Action Methods
- (void)actionInfo:(id)sender {
    [CHRouter.shared routeTo:@"/page/channel/detail" withParams:@{ @"cid": self.model.cid }];
}


@end
