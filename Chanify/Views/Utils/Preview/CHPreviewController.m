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

#if TARGET_OS_OSX

@implementation CHPreviewController

+ (instancetype)previewImages:(NSArray<CHPreviewItem *> *)images selected:(NSInteger)selected {
    return [self.class new];
}

+ (instancetype)previewFile:(NSURL *)fileURL {
    return [self.class new];
}


@end

#else

@interface CHPreviewController () <QLPreviewControllerDataSource>

@property (nonatomic, readonly, assign) BOOL isImage;
@property (nonatomic, readonly, strong) NSArray<id<QLPreviewItem>> *items;

@end

@implementation CHPreviewController

+ (instancetype)previewImages:(NSArray<CHPreviewItem *> *)images selected:(NSInteger)selected {
    return [[self.class alloc] initWithFiles:images selected:selected isImage:YES];
}

+ (instancetype)previewFile:(NSURL *)fileURL {
    return [[self.class alloc] initWithFiles:@[fileURL] selected:0 isImage:NO];
}

- (instancetype)initWithFiles:(NSArray<id<QLPreviewItem>> *)images selected:(NSInteger)selected isImage:(BOOL)isImage {
    if (self = [super init]) {
        _items = images;
        _isImage = isImage;
        self.dataSource = self;
        self.currentPreviewItemIndex = selected;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.isImage) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"square.and.arrow.down"] style:UIBarButtonItemStylePlain target:self action:@selector(actionShared:)];
    }
}

#pragma mark - QLPreviewControllerDataSource
- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
    return self.items.count;
}

- (id <QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {
    return [self.items objectAtIndex:index];
}

#pragma mark - Action Methods
- (void)actionShared:(UIBarButtonItem *)sender {
    NSURL *imageURL = [CHPreviewItem imageFileSharedURL:self.currentPreviewItem.previewItemURL];
    if (imageURL != nil) {
        [CHRouter.shared showShareItem:@[imageURL] sender:sender handler:^(BOOL completed, NSError *error) {
            if (error != nil) {
                [CHRouter.shared makeToast:@"Export failed".localized];
            } else if (completed) {
                [CHRouter.shared makeToast:@"Export success".localized];
            }
        }];
    }
}


@end

#endif
