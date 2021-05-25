//
//  CHFilesViewController.m
//  iOS
//
//  Created by WizJin on 2021/5/18.
//

#import "CHFilesViewController.h"
#import "CHLogic+iOS.h"
#import "CHRouter.h"

@interface CHFilesViewController ()

@property (nonatomic, readonly, strong) NSDirectoryEnumerator *enumerator;

@end

@implementation CHFilesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Files".localized;

    _enumerator = [NSFileManager.defaultManager enumeratorAtURL:CHLogic.shared.webFileManager.fileBaseDir includingPropertiesForKeys:@[NSURLTotalFileAllocatedSizeKey] options:0 errorHandler:nil];
}


@end
