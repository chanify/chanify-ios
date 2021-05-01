//
//  CHPreviewController.h
//  Chanify
//
//  Created by WizJin on 2021/3/30.
//

#import "CHPreviewItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHPreviewController : QLPreviewController

+ (instancetype)previewImages:(NSArray<CHPreviewItem *> *)images selected:(NSInteger)selected;
+ (instancetype)previewFile:(NSURL *)fileURL;


@end

NS_ASSUME_NONNULL_END
