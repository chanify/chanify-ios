//
//  CHNodeViewController.m
//  Chanify
//
//  Created by WizJin on 2021/2/25.
//

#import "CHNodeViewController.h"
#import <Masonry/Masonry.h>
#import "CHUserDataSource.h"
#import "CHNodeModel.h"
#import "CHLogic.h"
#import "CHRouter.h"
#import "CHTheme.h"

typedef UITableViewDiffableDataSource<NSString *, UIListContentConfiguration *> CHNodeDataSource;
typedef NSDiffableDataSourceSnapshot<NSString *, UIListContentConfiguration *> CHNodeDiffableSnapshot;

static NSString *const cellIdentifier = @"cell";
static NSString *const headIdentifier = @"head";

@interface CHNodeViewController () <UITableViewDelegate>

@property (nonatomic, readonly, strong) CHNodeModel *model;
@property (nonatomic, readonly, strong) CHNodeDataSource *dataSource;

@end

@implementation CHNodeViewController

- (instancetype)initWithParameters:(NSDictionary *)params {
    if (self = [super init]) {
        _model = [CHLogic.shared.userDataSource nodeWithNID:[params valueForKey:@"mid"]];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Node Detail".localized;
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    [self.view addSubview:tableView];
    [tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [tableView registerClass:UITableViewHeaderFooterView.class forHeaderFooterViewReuseIdentifier:headIdentifier];
    [tableView registerClass:UITableViewCell.class forCellReuseIdentifier:cellIdentifier];
    tableView.delegate = self;
    
    _dataSource = [[CHNodeDataSource alloc] initWithTableView:tableView cellProvider:^UITableViewCell *(UITableView *tableView, NSIndexPath *indexPath, UIListContentConfiguration *item) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        if (cell != nil) {
            cell.contentConfiguration = item;
        }
        return cell;
    }];

    CHNodeDiffableSnapshot *snapshot = [CHNodeDiffableSnapshot new];
    [snapshot appendSectionsWithIdentifiers:@[@""]];
    [snapshot appendItemsWithIdentifiers:@[
        [self valueItem:@"Name" value:self.model.name],
        [self valueItem:@"Host" value:self.model.url],
    ]];
    
    [snapshot appendSectionsWithIdentifiers:@[@"Features".localized]];
    [snapshot appendItemsWithIdentifiers:@[
        [self featureItem:@"msg.text" icon:@"doc.plaintext"],
    ]];

    [self.dataSource applySnapshot:snapshot animatingDifferences:NO];
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UITableViewHeaderFooterView *headerView = nil;
    NSArray<NSString *> *sections = [self.dataSource.snapshot sectionIdentifiers];
    if (section < sections.count) {
        headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:headIdentifier];
        if (headerView != nil) {
            headerView.textLabel.text = [sections objectAtIndex:section];
        }
    }
    return headerView;
}

#pragma mark - Private Methods
- (UIListContentConfiguration *)valueItem:(NSString *)name value:(NSString *)value {
    UIListContentConfiguration *item = UIListContentConfiguration.valueCellConfiguration;
    item.text = name.localized;
    item.secondaryText = value;
    return item;
}

- (UIListContentConfiguration *)featureItem:(NSString *)name icon:(NSString *)icon {
    UIListContentConfiguration *item = UIListContentConfiguration.valueCellConfiguration;
    item.text = name.localized;
    item.image = [UIImage systemImageNamed:icon];
    return item;
}


@end
