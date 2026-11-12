//
//  CHChannelsViewController.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHChannelsViewController.h"
#import <Masonry/Masonry.h>
#import "CHChannelTableViewCell.h"
#import "CHNavigationTitleView.h"
#import "CHTableView.h"
#import "CHUserDataSource.h"
#import "CHMessageModel.h"
#import "CHRouter.h"
#import "CHLogic.h"
#import "CHMessageSearch.h"

@interface CHMessageSearchResultCell : UITableViewCell
@property (nonatomic, strong) UILabel *channelLabel;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *bodyLabel;
@end

@implementation CHMessageSearchResultCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)identifier {
    if (self = [super initWithStyle:style reuseIdentifier:identifier]) {
        _channelLabel = [UILabel new];
        _dateLabel = [UILabel new];
        _titleLabel = [UILabel new];
        _bodyLabel = [UILabel new];
        for (UILabel *label in @[_channelLabel, _dateLabel, _titleLabel, _bodyLabel]) label.adjustsFontForContentSizeCategory = YES;
        _channelLabel.font = _dateLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
        _channelLabel.textColor = _dateLabel.textColor = UIColor.secondaryLabelColor;
        _channelLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [_dateLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [_dateLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        _titleLabel.numberOfLines = 2;
        _bodyLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        _bodyLabel.textColor = UIColor.secondaryLabelColor;
        _bodyLabel.numberOfLines = 2;
        UIStackView *metadata = [[UIStackView alloc] initWithArrangedSubviews:@[_channelLabel, _dateLabel]];
        metadata.spacing = 8;
        metadata.alignment = UIStackViewAlignmentFirstBaseline;
        UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[metadata, _titleLabel, _bodyLabel]];
        stack.axis = UILayoutConstraintAxisVertical;
        stack.spacing = 4;
        [self.contentView addSubview:stack];
        [stack mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(self.contentView).inset(12);
            make.left.right.equalTo(self.contentView).inset(16);
        }];
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return self;
}
@end

// Kept local to the channel list: this is the only search entry point.
@interface CHMessageSearchResultsController : UITableViewController
@property (nonatomic, strong) CHUserDataSource *account;
@property (nonatomic, strong) CHMessageSearch *search;
@property (nonatomic, copy) NSString *query;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *items;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic) BOOL more;
@property (nonatomic) BOOL loading;
@property (nonatomic) NSUInteger revision;
- (void)updateQuery:(NSString *)query;
- (void)updateQuery:(NSString *)query force:(BOOL)force;
@end

@implementation CHMessageSearchResultsController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.items = [NSMutableArray new];
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 110;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(refreshResults:) forControlEvents:UIControlEventValueChanged];
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 60)];
    self.statusLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    self.statusLabel.textColor = UIColor.secondaryLabelColor;
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.numberOfLines = 0;
    self.statusLabel.adjustsFontForContentSizeCategory = YES;
    self.tableView.tableHeaderView = self.statusLabel;
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(indexUpdated:) name:@"CHMessageSearchDidUpdate" object:nil];
}

- (void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)setStatus:(NSString *)text {
    self.statusLabel.text = text;
    CGFloat width = self.tableView.bounds.size.width;
    CGFloat height = [self.statusLabel sizeThatFits:CGSizeMake(MAX(width - 32, 1), CGFLOAT_MAX)].height + 24;
    self.statusLabel.frame = CGRectMake(0, 0, width, MAX(height, 50));
    self.tableView.tableHeaderView = text.length ? self.statusLabel : nil;
}

- (void)updateQuery:(NSString *)query { [self updateQuery:query force:NO]; }

- (void)updateQuery:(NSString *)query force:(BOOL)force {
    [self loadViewIfNeeded];
    NSString *trimmed = [query stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (!force && [self.query isEqualToString:trimmed] && self.account == CHLogic.shared.userDataSource && (self.items.count || self.loading)) return;
    self.revision++;
    [self.search cancelSearch];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(loadFirstPage) object:nil];
    self.account = CHLogic.shared.userDataSource;
    self.search = self.account.messageSearch;
    self.query = [query stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    self.loading = NO;
    self.more = NO;
    [self.items removeAllObjects];
    [self.tableView reloadData];
    [self setStatus:self.query.length ? @"Searching…".localized : @"Search message titles and text".localized];
    if (self.query.length) [self performSelector:@selector(loadFirstPage) withObject:nil afterDelay:0.3];
}

- (void)refreshResults:(UIRefreshControl *)sender {
    [self updateQuery:self.query force:YES];
    [sender endRefreshing];
}

- (void)loadFirstPage { [self loadPage:NO]; }

- (void)loadPage:(BOOL)append {
    if (self.loading || !self.query.length || self.account != CHLogic.shared.userDataSource) return;
    if (!self.search) { [self setStatus:@"Message search is unavailable".localized]; return; }
    self.loading = YES;
    NSUInteger revision = self.revision;
    NSString *before = append ? self.items.lastObject[@"mid"] : nil;
    __weak typeof(self) weakSelf = self;
    [self.search search:self.query before:before limit:30 completion:^(NSArray<NSDictionary *> *results, BOOL more, BOOL incomplete, NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || revision != self.revision || self.account != CHLogic.shared.userDataSource) return;
        self.loading = NO;
        self.more = more && !error;
        if (error) {
            [self setStatus:[error.domain isEqualToString:@"ChanifySearch"] && error.code == 1 ? @"Use up to 256 characters to search".localized : @"Search could not finish. Try a longer keyword or try again.".localized];
            return;
        }
        if (!append) [self.items removeAllObjects];
        [self.items addObjectsFromArray:results];
        [self setStatus:incomplete ? (self.items.count ? @"Some messages are not yet searchable".localized : @"No matching messages in the current search index".localized) : (self.items.count ? @"" : @"No matching messages".localized)];
        [self.tableView reloadData];
    }];
}

- (void)indexUpdated:(NSNotification *)notification {
    if (notification.object != self.search || !self.view.window || self.loading || !self.query.length) return;
    if (self.tableView.contentOffset.y <= 0 && !self.tableView.dragging) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(loadFirstPage) object:nil];
        [self performSelector:@selector(loadFirstPage) withObject:nil afterDelay:0.4];
    }
}

- (NSString *)snippet:(NSString *)text {
    NSRange hit = [text rangeOfString:self.query options:NSCaseInsensitiveSearch];
    NSUInteger start = hit.location != NSNotFound && hit.location > 20 ? hit.location - 20 : 0;
    NSUInteger length = hit.location == NSNotFound ? 150 : MAX((NSUInteger)150, NSMaxRange(hit) - start + 20);
    NSRange range = [text rangeOfComposedCharacterSequencesForRange:NSMakeRange(start, MIN(length, text.length-start))];
    return [NSString stringWithFormat:@"%@%@%@", start ? @"…" : @"", [text substringWithRange:range], NSMaxRange(range) < text.length ? @"…" : @""];
}

- (NSAttributedString *)highlight:(NSString *)text {
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:text];
    if (!self.query.length) return result;
    NSUInteger offset = 0;
    while (offset < text.length) {
        NSRange range = [text rangeOfString:self.query options:NSCaseInsensitiveSearch range:NSMakeRange(offset, text.length-offset)];
        if (range.location == NSNotFound) break;
        [result addAttribute:NSBackgroundColorAttributeName value:[UIColor.systemYellowColor colorWithAlphaComponent:0.35] range:range];
        offset = NSMaxRange(range);
    }
    return result;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return self.items.count; }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CHMessageSearchResultCell *cell = [tableView dequeueReusableCellWithIdentifier:@"message-search"];
    if (!cell) cell = [[CHMessageSearchResultCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"message-search"];
    NSDictionary *item = self.items[indexPath.row];
    NSString *title = item[@"title"];
    NSString *body = [self snippet:item[@"text"]];
    NSString *channel = item[@"channel"];
    if (!channel.length) channel = [CHChannelModel modelWithCID:[item[@"cid"] base64Code] name:nil icon:nil].title ?: @"Chanify";
    cell.channelLabel.text = channel;
    cell.dateLabel.text = [[NSDate dateFromMID:item[@"mid"]] mediumFormat] ?: @"";
    cell.titleLabel.hidden = !title.length;
    cell.titleLabel.attributedText = [self highlight:[self snippet:title]];
    cell.bodyLabel.hidden = !body.length;
    cell.bodyLabel.attributedText = [self highlight:body];
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.more && indexPath.row >= (NSInteger)self.items.count - 5) [self loadPage:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.account != CHLogic.shared.userDataSource) return;
    NSDictionary *item = self.items[indexPath.row];
    CHMessageModel *message = [self.account messageWithMID:item[@"mid"]];
    if (!message) {
        [CHRouter.shared makeToast:@"This message is no longer available".localized];
        [self updateQuery:self.query force:YES];
        return;
    }
    [self.view endEditing:YES];
    [CHRouter.shared routeTo:@"/page/channel" withParams:@{ @"cid": message.channel.base64Code, @"mid": message.mid, @"show": @"detail" }];
}
@end

typedef UITableViewDiffableDataSource<NSString *, CHChannelModel *> CHChannelDataSource;
typedef NSDiffableDataSourceSnapshot<NSString *, CHChannelModel *> CHChannelDiffableSnapshot;

static NSString *const cellIdentifier = @"chan";

@interface CHChannelsViewController () <UITableViewDelegate, CHLogicDelegate, UISearchResultsUpdating, UISearchControllerDelegate>

@property (nonatomic, strong) CHMessageSearchResultsController *searchResults;
@property (nonatomic, assign) BOOL showAllChannels;
@property (nonatomic, readonly, strong) CHTableView *tableView;
@property (nonatomic, readonly, strong) CHChannelDataSource *dataSource;

@end

@implementation CHChannelsViewController

- (void)dealloc {
    [CHLogic.shared removeDelegate:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _showAllChannels = NO;
    self.searchResults = [[CHMessageSearchResultsController alloc] initWithStyle:UITableViewStylePlain];
    UISearchController *search = [[UISearchController alloc] initWithSearchResultsController:self.searchResults];
    search.searchResultsUpdater = self;
    search.delegate = self;
    search.searchBar.placeholder = @"Search messages".localized;
    search.hidesNavigationBarDuringPresentation = NO;
    search.showsSearchResultsController = YES;
    self.navigationItem.searchController = search;
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    if (@available(iOS 16.0, *)) self.navigationItem.preferredSearchBarPlacement = UINavigationItemSearchBarPlacementStacked;
    self.definesPresentationContext = YES;
    
    self.navigationItem.titleView = [[CHNavigationTitleView alloc] initWithNavigationController:self.navigationController];

    @weakify(self);
    NSArray *actions = @[
        [UIAction actionWithTitle:@"Scan QR Code".localized image:[UIImage systemImageNamed:@"qrcode.viewfinder"] identifier:@"scan" handler:^(UIAction *action) {
            [CHRouter.shared routeTo:@"/page/scan" withParams:@{ @"show": @"detail" }];
        }],
        [UIAction actionWithTitle:@"New Channel".localized image:[UIImage systemImageNamed:@"plus"] identifier:@"new" handler:^(UIAction *action) {
            [CHRouter.shared routeTo:@"/page/channel/new" withParams:@{ @"show": @"detail" }];
        }],
        [UIAction actionWithTitle:@"Show/Hide Channels".localized image:[UIImage systemImageNamed:@"eye"] identifier:@"hidden" handler:^(__kindof UIAction * _Nonnull action) {
            @strongify(self);
            self.showAllChannels = !self.showAllChannels;
            [self updateMenus];
            [self reloadDataAnimated:YES];
        }],
    ];
    
    UIBarButtonItem *barItem = [[UIBarButtonItem alloc] initWithPrimaryAction:actions[0]];
    barItem.menu = [UIMenu menuWithChildren:actions];
    self.navigationItem.rightBarButtonItem = barItem;

    CHTableView *tableView = [CHTableView new];
    [self.view addSubview:(_tableView = tableView)];
    [tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.left.right.bottom.equalTo(self.view);
    }];
    [tableView registerClass:CHChannelTableViewCell.class forCellReuseIdentifier:cellIdentifier];
    tableView.rowHeight = 71;
    tableView.delegate = self;

    _dataSource = [[CHChannelDataSource alloc] initWithTableView:tableView cellProvider:^UITableViewCell *(UITableView *tableView, NSIndexPath *indexPath, CHChannelModel *item) {
        CHChannelTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        if (cell != nil) {
            cell.model = item;
        }
        return cell;
    }];

    CHLogic *logic = CHLogic.shared;
    [logic addDelegate:self];
    [self updateTitleWithUnread:logic.unreadSumAllChannel];
    [self reloadDataAnimated:NO];
    [self updateMenus];
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    [self.searchResults updateQuery:searchController.searchBar.text ?: @""];
}

- (void)didDismissSearchController:(UISearchController *)searchController {
    [self.searchResults updateQuery:@""];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.searchResults.account && self.searchResults.account != CHLogic.shared.userDataSource) {
        self.navigationItem.searchController.active = NO;
        [self.searchResults updateQuery:@""];
    }
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    CHChannelModel *item = [self.dataSource itemIdentifierForIndexPath:indexPath];
    if (item != nil) {
        [CHRouter.shared routeTo:@"/page/channel" withParams:@{ @"cid": item.cid, @"show": @"detail" }];
    }
}

- (nullable UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *actions = [NSMutableArray arrayWithCapacity:3];
    [actions addObject:[CHChannelTableViewCell actionInfo:tableView indexPath:indexPath]];
    [actions addObject:[CHChannelTableViewCell actionHidden:tableView indexPath:indexPath]];
    UIContextualAction *delete = [CHChannelTableViewCell actionDelete:tableView indexPath:indexPath];
    if (delete != nil) {
        [actions insertObject:delete atIndex:0];
    }
    UISwipeActionsConfiguration *configuration = [UISwipeActionsConfiguration configurationWithActions:actions];
    configuration.performsFirstActionWithFullSwipe = NO;
    return configuration;
}

#pragma mark - CHLogicDelegate
- (void)logicChannelUpdated:(NSString *)cid {
    [self reloadDataAnimated:NO];
}

- (void)logicChannelsUpdated:(NSArray<NSString *> *)cids {
    [self reloadDataAnimated:NO];
}

- (void)logicChannelListUpdated:(NSArray<NSString *> *)cids {
    [self reloadDataAnimated:YES];
}

- (void)logicMessagesUpdated:(NSArray<NSString *> *)mids {
    CHUserDataSource *usrDS = CHLogic.shared.userDataSource;
    CHChannelDiffableSnapshot *snapshot = self.dataSource.snapshot;
    NSArray<CHChannelModel *> *items = [snapshot itemIdentifiersInSectionWithIdentifier:@"main"];
    NSHashTable *reloadItems = [NSHashTable weakObjectsHashTable];
    for (NSString *mid in mids) {
        CHMessageModel *model = [usrDS messageWithMID:mid];
        NSString *cid = model.channel.base64Code;
        for (CHChannelModel *c in items) {
            if ([c.cid isEqualToString:cid]) {
                c.mid = mid;
                [reloadItems addObject:c];
                break;
            }
        }
    }
    if (reloadItems.count != 1 || reloadItems.anyObject != items.firstObject) {
        // TODO: sort items
        [snapshot deleteSectionsWithIdentifiers:@[@"main"]];
        [snapshot appendSectionsWithIdentifiers:@[@"main"]];
        [snapshot appendItemsWithIdentifiers:[items sortedArrayUsingSelector:@selector(channelCompare:)]];
    }
    [snapshot reloadItemsWithIdentifiers:reloadItems.allObjects];
    [self.dataSource applySnapshot:snapshot animatingDifferences:YES];
}

- (void)logicMessagesUnreadChanged:(NSNumber *)unread {
    [self updateTitleWithUnread:unread.integerValue];
}

#pragma mark - Private Methods
- (void)reloadDataAnimated:(BOOL)animated {
    NSArray<CHChannelModel *> *items = [CHLogic.shared.userDataSource loadChannelsIncludeHidden:self.showAllChannels];
    CHChannelDiffableSnapshot *snapshot = [CHChannelDiffableSnapshot new];
    [snapshot appendSectionsWithIdentifiers:@[@"main"]];
    [snapshot appendItemsWithIdentifiers:[items sortedArrayUsingSelector:@selector(channelCompare:)]];
    [self.dataSource applySnapshot:snapshot animatingDifferences:animated];
}

- (void)updateTitleWithUnread:(NSInteger)unread {
    NSString *badge = nil;
    NSString *title = self.title;
    if (unread > 0) {
        badge = (unread > 99 ? @"⋯" : [NSString stringWithFormat:@"%ld", (long)unread]);
        title = [title stringByAppendingString:(unread > 999 ? @" (999+)" : [NSString stringWithFormat:@" (%ld)", (long)unread])];
    }
    [(CHNavigationTitleView *)self.navigationItem.titleView setTitle:title];
    self.tabBarItem.badgeValue = badge;
}

- (void)updateMenus {
    Class immutableClz = NSClassFromString(@"_UIImmutableAction");
    UIMenu *menu = self.navigationItem.rightBarButtonItem.menu;
    for (UIMenuElement *item in menu.children) {
        if ([item isKindOfClass:UIAction.class] && ![item isKindOfClass:immutableClz]) {
            UIAction *action = (UIAction *)item;
            if ([action.identifier isEqualToString:@"hidden"]) {
                BOOL showAll = self.showAllChannels;
                action.title = (showAll  ? @"Hide Channels" : @"Show Channels").localized;
                action.image = [UIImage systemImageNamed:(showAll ? @"eye.slash" : @"eye")];
                break;
            }
        }
    }
}


@end
