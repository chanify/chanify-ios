//
//  CHFilesViewController.m
//  iOS
//
//  Created by WizJin on 2021/5/18.
//

#import "CHFilesViewController.h"
#import "CHLogic+iOS.h"

@interface CHFilesViewController ()

@property (nonatomic, readonly, strong) NSDirectoryEnumerator *enumerator;

@end

@implementation CHFilesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Files".localized;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"trash"] style:UIBarButtonItemStylePlain target:self action:@selector(actionCleanup:)];
    _enumerator = [NSFileManager.defaultManager enumeratorAtURL:CHLogic.shared.webFileManager.fileBaseDir includingPropertiesForKeys:@[NSURLTotalFileAllocatedSizeKey] options:0 errorHandler:nil];
}

#pragma mark - Private Methods
- (void)actionCleanup:(id)sender {
    
}


@end
