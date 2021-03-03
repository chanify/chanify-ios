//
//  CHNodeViewController.m
//  Chanify
//
//  Created by WizJin on 2021/2/25.
//

#import "CHNodeViewController.h"
#import <Masonry/Masonry.h>
#import "CHFormItem.h"
#import "CHUserDataSource.h"
#import "CHNSDataSource.h"
#import "CHNodeModel.h"
#import "CHLogic.h"
#import "CHRouter.h"
#import "CHTheme.h"
#import "CHLogic.h"
#import "CHCrpyto.h"

typedef NS_ENUM(NSInteger, CHNodeVCStatus) {
    CHNodeVCStatusNone      = 0,
    CHNodeVCStatusShow      = 1,
    CHNodeVCStatusNew       = 2,
    CHNodeVCStatusUpdate    = 3,
};

typedef UITableViewDiffableDataSource<NSString *, CHFormItem *> CHNodeDataSource;
typedef NSDiffableDataSourceSnapshot<NSString *, CHFormItem *> CHNodeDiffableSnapshot;

static NSString *const cellIdentifier = @"cell";
static NSString *const headIdentifier = @"head";

@interface CHNodeViewController () <UITableViewDelegate>

@property (nonatomic, readonly, assign) CHNodeVCStatus status;
@property (nonatomic, readonly, strong) CHNodeModel *model;
@property (nonatomic, readonly, strong) CHNodeDataSource *dataSource;
@property (nonatomic, readonly, strong) NSString *token;

@end

@implementation CHNodeViewController

- (instancetype)initWithParameters:(NSDictionary *)params {
    if (self = [super init]) {
        _status = CHNodeVCStatusNone;
        NSString *endpoint = [params valueForKey:@"endpoint"];
        if (endpoint.length > 0) {
            [CHRouter.shared showIndicator:YES];
            NSURL *url = [NSURL URLWithString:@"/rest/v1/info" relativeToURL:[NSURL URLWithString:endpoint]];
            NSDictionary *info = [NSDictionary dictionaryWithJSONData:[NSData dataWithContentsOfURL:url]];
            [CHRouter.shared showIndicator:NO];
            if (info.count > 0) {
                NSString *nid = [info valueForKey:@"nodeid"];
                if (nid.length > 0) {
                    _model = [CHNodeModel modelWithNID:nid name:[info valueForKey:@"name"] endpoint:[info valueForKey:@"endpoint"] features:[[info valueForKey:@"features"] componentsJoinedByString:@","]];
                    CHNodeModel *model = [CHLogic.shared.userDataSource nodeWithNID:nid];
                    if (model == nil) {
                        _status = CHNodeVCStatusNew;
                    } else {
                        if ([self.model isFullEqual:model]) {
                            _status = CHNodeVCStatusShow;
                        } else {
                            _status = CHNodeVCStatusUpdate;
                        }
                    }
                }
            }
        }
        if (_model == nil) {
            NSString *nid = [params valueForKey:@"nid"];
            if (nid.length > 0) {
                _model = [CHLogic.shared.userDataSource nodeWithNID:nid];
                _status = CHNodeVCStatusShow;
            }
        }
        if (_model != nil) {
            if ([self.model.nid isEqualToString:@"sys"]) {
                _status = CHNodeVCStatusNone;
            }
        } else {
            @weakify(self);
            dispatch_main_async(^{
                @strongify(self);
                [self closeAnimated:YES completion:nil];
                [CHRouter.shared makeToast:@"Connect node server failed".localized];
            });
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    
    
    
    
    
    
    
    
    @weakify(self);
    
    self.title = @"Node Detail".localized;
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    [self.view addSubview:tableView];
    [tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [tableView registerClass:UITableViewHeaderFooterView.class forHeaderFooterViewReuseIdentifier:headIdentifier];
    [tableView registerClass:UITableViewCell.class forCellReuseIdentifier:cellIdentifier];
    tableView.delegate = self;
    
    _dataSource = [[CHNodeDataSource alloc] initWithTableView:tableView cellProvider:^UITableViewCell *(UITableView *tableView, NSIndexPath *indexPath, CHFormItem *item) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        if (cell != nil) {
            cell.contentConfiguration = item.configuration;
        }
        return cell;
    }];
    
    NSMutableArray<CHFormItem *> *features = [NSMutableArray arrayWithCapacity:self.model.features.count];
    for (NSString *feature in self.model.features) {
        [features addObject: [CHFormItem itemWithName:feature image:[self featureIconWithName:feature]]];
    }

    CHNodeDiffableSnapshot *snapshot = [CHNodeDiffableSnapshot new];
    [snapshot appendSectionsWithIdentifiers:@[@"Information".localized]];
    [snapshot appendItemsWithIdentifiers:@[
        [CHFormItem itemWithName:@"Name" value:self.model.name],
        [CHFormItem itemWithName:@"Endpoint" value:self.model.endpoint],
    ]];
    [snapshot appendSectionsWithIdentifiers:@[@"Features".localized]];
    [snapshot appendItemsWithIdentifiers:features];

    [snapshot appendSectionsWithIdentifiers:@[@""]];
    switch (self.status) {
        case CHNodeVCStatusNone:
            break;
        case CHNodeVCStatusShow:
        {
            [snapshot appendItemsWithIdentifiers:@[[CHFormItem itemWithName:@"Delete node" action:^{
                @strongify(self);
                [self actionDeleteNode];
            }]]];
        }
            break;
        case CHNodeVCStatusNew:
        {
            [snapshot appendItemsWithIdentifiers:@[[CHFormItem itemWithName:@"Add node" action:^{
                @strongify(self);
                [self actionAddNode];
            }]]];
        }
            break;
        case CHNodeVCStatusUpdate:
        {
            [snapshot appendItemsWithIdentifiers:@[[CHFormItem itemWithName:@"Update node" action:^{
                @strongify(self);
                [self actionUpdateNode];
            }]]];
        }
            break;
    }
    [self.dataSource applySnapshot:snapshot animatingDifferences:NO];
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    CHFormItem *item = [self.dataSource itemIdentifierForIndexPath:indexPath];
    if (item.action != nil) {
        item.action();
    }
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

#pragma mark - Action Methods
- (void)actionAddNode {
    [CHRouter.shared showIndicator:YES];
    [CHLogic.shared insertNode:self.model completion:^(CHLCode result) {
        [CHRouter.shared showIndicator:NO];
        if (result != CHLCodeOK) {
            [CHRouter.shared makeToast:@"Add node failed".localized];
        } else {
            [self closeAnimated:YES completion:nil];
        }
    }];
}

- (void)actionUpdateNode {
    [CHLogic.shared updateNode:self.model];
    [self closeAnimated:YES completion:nil];
}

- (void)actionDeleteNode {
    [CHLogic.shared deleteNode:self.model.nid];
    [self closeAnimated:YES completion:nil];
}

#pragma mark - Private Methods
- (UIImage *)featureIconWithName:(NSString *)name {
    UIImage *image = nil;
    if ([name hasPrefix:@"msg.text"]) {
        image = [UIImage systemImageNamed:@"doc.plaintext"];
    } else if ([name isEqualToString:@"store.device"]) {
        image = [UIImage systemImageNamed:@"apps.iphone"];
    }
    return image;
}


@end
