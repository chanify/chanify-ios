//
//  CHPreviewItem.h
//  Chanify
//
//  Created by WizJin on 2021/3/30.
//

#import <QuickLook/QuickLook.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHPreviewItem : NSObject <QLPreviewItem>

@property (nonatomic, readwrite, strong) NSURL *previewItemURL;
@property (nonatomic, readwrite, strong) NSString *previewItemTitle;
@property (nonatomic, readwrite, strong) NSString *previewItemContentType;

+ (instancetype)itemWithURL:(NSURL *)url title:(NSString *)title uti:(NSString *)uti;


@end

NS_ASSUME_NONNULL_END
