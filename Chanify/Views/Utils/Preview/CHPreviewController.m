//
//  CHPreviewController.m
//  Chanify
//
//  Created by WizJin on 2021/3/30.
//

#import "CHPreviewController.h"
#import "CHPreviewItem.h"
#import "CHRouter.h"
#import "CHLogic.h"

@interface CHPreviewController () <QLPreviewControllerDataSource>

@property (nonatomic, readonly, strong) NSArray<CHPreviewItem *> *items;

@end

@implementation CHPreviewController

+ (instancetype)previewImages:(NSArray<CHPreviewItem *> *)images selected:(NSInteger)selected {
    return [[self.class alloc] initWithImages:images selected:selected];
}

- (instancetype)initWithImages:(NSArray<CHPreviewItem *> *)images selected:(NSInteger)selected {
    if (self = [super init]) {
        _items = images;
        self.dataSource = self;
        self.currentPreviewItemIndex = selected;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"square.and.arrow.down"] style:UIBarButtonItemStylePlain target:self action:@selector(actionShared:)];
}

#pragma mark - QLPreviewControllerDataSource
- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
    return self.items.count;
}

- (id <QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {
    return [self.items objectAtIndex:index];
}

#pragma mark - Action Methods
- (void)actionShared:(id)sender {
    UIImage *image = [UIImage imageWithData:[NSData dataFromNoCacheURL:self.currentPreviewItem.previewItemURL]];
    [CHRouter.shared showShareItem:@[image] sender:sender handler:^(BOOL completed, NSError *error) {
        if (error != nil) {
            [CHRouter.shared makeToast:@"Export failed".localized];
        } else if (completed) {
            [CHRouter.shared makeToast:@"Export success".localized];
        }
    }];
}


@end
