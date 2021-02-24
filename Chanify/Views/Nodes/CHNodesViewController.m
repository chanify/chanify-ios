//
//  CHNodesViewController.m
//  Chanify
//
//  Created by WizJin on 2021/2/23.
//

#import "CHNodesViewController.h"
#import <Masonry/Masonry.h>
#import "CHNodeTableView.h"
#import "CHRouter.h"

@interface CHNodesViewController () <UITableViewDelegate>

@property (nonatomic, readonly, strong) CHTableView *tableView;

@end

@implementation CHNodesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"plus.circle"] style:UIBarButtonItemStylePlain target:self action:@selector(actionAddNode:)];
    
    CHTableView *tableView = [CHTableView new];
    [self.view addSubview:(_tableView = tableView)];
    [tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    tableView.delegate = self;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Action Methods
- (void)actionAddNode:(id)sender {
    [CHRouter.shared routeTo:@"/page/scan"];
}


@end
