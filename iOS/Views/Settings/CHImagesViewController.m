//
//  CHImagesViewController.m
//  iOS
//
//  Created by WizJin on 2021/5/18.
//

#import "CHImagesViewController.h"
#import "CHTableView.h"
#import "CHLogic+iOS.h"

typedef UITableViewDiffableDataSource<NSString *, NSURL *> CHImagesDataSource;
typedef NSDiffableDataSourceSnapshot<NSString *, NSURL *> CHImagesDiffableSnapshot;

@interface CHImagesViewController ()

@property (nonatomic, readonly, strong) CHTableView *listView;
@property (nonatomic, readonly, strong) CHImagesDataSource *dataSource;
@property (nonatomic, readonly, strong) NSDirectoryEnumerator *enumerator;

@end

@implementation CHImagesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Images".localized;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"trash"] style:UIBarButtonItemStylePlain target:self action:@selector(actionCleanup:)];
    _enumerator = [NSFileManager.defaultManager enumeratorAtURL:CHLogic.shared.webImageManager.fileBaseDir includingPropertiesForKeys:@[NSURLTotalFileAllocatedSizeKey] options:0 errorHandler:nil];
}

#pragma mark - Private Methods
- (void)actionCleanup:(id)sender {
    
}


@end
