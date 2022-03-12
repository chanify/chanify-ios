//
//  CHSoundsViewController.m
//  Chanify
//
//  Created by WizJin on 2021/3/26.
//

#import "CHSoundsViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import <Masonry/Masonry.h>
#import "CHLoadMoreView.h"
#import "CHTableView.h"
#import "CHSoundCell.h"
#import "CHAudioPlayer.h"
#import "CHPasteboard.h"
#import "CHLogic.h"
#import "CHTheme.h"

static NSString *const cellIdentifier = @"cell";

typedef UITableViewDiffableDataSource<NSString *, NSString *> CHSoundsDataSource;
typedef NSDiffableDataSourceSnapshot<NSString *, NSString *> CHSoundsDiffableSnapshot;

@interface CHSoundsViewController () <UITableViewDelegate>

@property (nonatomic, readonly, strong) CHTableView *tableView;
@property (nonatomic, readonly, strong) CHSoundsDataSource *dataSource;
@property (nonatomic, readonly, strong) NSString *defaultSoundName;

@end

@implementation CHSoundsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Sound".localized;
    
    CHTableView *tableView = [CHTableView new];
    [self.view addSubview:(_tableView = tableView)];
    [tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.left.right.bottom.equalTo(self.view);
    }];
    [tableView registerClass:CHSoundCell.class forCellReuseIdentifier:cellIdentifier];
    tableView.tableFooterView = [CHLoadMoreView loadMoreWithStatus:CHLoadStatusFinish];
    tableView.rowHeight = 50;
    tableView.allowsSelectionDuringEditing = YES;
    tableView.allowsMultipleSelectionDuringEditing = YES;
    tableView.delegate = self;
    
    @weakify(self);
    _dataSource = [[CHSoundsDataSource alloc] initWithTableView:tableView cellProvider:^UITableViewCell *(UITableView *tableView, NSIndexPath *indexPath, NSString *filePath) {
        CHSoundCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        if (cell != nil) {
            @strongify(self);
            cell.check = [filePath.lastPathComponent.stringByDeletingPathExtension isEqualToString:self.defaultSoundName];
            cell.filePath = filePath;
        }
        return cell;
    }];

    [self reloadData:NO];
}

#pragma mark - Private Methods
- (void)reloadData:(BOOL)animated {
    _defaultSoundName = CHLogic.shared.defaultNotificationSound;

    CHSoundsDiffableSnapshot *snapshot = [CHSoundsDiffableSnapshot new];
    [snapshot appendSectionsWithIdentifiers:@[@""]];
    NSMutableArray *items = [NSMutableArray arrayWithObject:@""];
    [items addObjectsFromArray:CHLogic.shared.soundManager.soundFiles];
    [snapshot appendItemsWithIdentifiers:items];
    [self.dataSource applySnapshot:snapshot animatingDifferences:animated];
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *filePath = [self.dataSource itemIdentifierForIndexPath:indexPath];
    if (filePath.length <= 0) {
        AudioServicesPlayAlertSound(kCHDefaultNotificationSoundID);
    } else {
        [CHAudioPlayer.shared playWithURL:[NSURL fileURLWithPath:filePath] title:filePath.lastPathComponent.stringByDeletingPathExtension];
    }
    NSString *code = filePath.lastPathComponent.stringByDeletingPathExtension;
    if (![code isEqualToString:self.defaultSoundName]) {
        _defaultSoundName = code;
        CHLogic.shared.defaultNotificationSound = self.defaultSoundName;
        @weakify(self);
        dispatch_main_async(^{
            @strongify(self);
            [self.tableView reloadData];
        });
    }
}

- (nullable UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    UISwipeActionsConfiguration *configuration = nil;
    NSString *code = [self.dataSource itemIdentifierForIndexPath:indexPath].lastPathComponent.stringByDeletingPathExtension;
    if (code.length > 0) {
        UIContextualAction *action = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:nil handler:^(UIContextualAction *action, UIView *sourceView, void (^completionHandler)(BOOL)) {
            [CHPasteboard.shared copyWithName:@"Sound Code".localized value:code];
            completionHandler(YES);
        }];
        action.image = [UIImage systemImageNamed:@"doc.on.doc.fill"];
        action.backgroundColor = CHTheme.shared.secureColor;
        configuration = [UISwipeActionsConfiguration configurationWithActions:@[action]];
    }
    return configuration;
}


@end
