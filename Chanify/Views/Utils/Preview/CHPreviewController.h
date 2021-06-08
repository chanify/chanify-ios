//
//  CHPreviewController.h
//  Chanify
//
//  Created by WizJin on 2021/3/30.
//

#import "CHPreviewItem.h"
#import "CHUI.h"

NS_ASSUME_NONNULL_BEGIN

#if TARGET_OS_OSX
@interface CHPreviewController : NSObject
#else
@interface CHPreviewController : QLPreviewController
#endif

+ (instancetype)previewImages:(NSArray<CHPreviewItem *> *)images selected:(NSInteger)selected;
+ (instancetype)previewFile:(NSURL *)fileURL;


@end

NS_ASSUME_NONNULL_END
