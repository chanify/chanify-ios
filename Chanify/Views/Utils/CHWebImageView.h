//
//  CHWebImageView.h
//  Chanify
//
//  Created by WizJin on 2021/3/27.
//

#import <UIKit/UIKit.h>
#import "CHWebObjectManager.h"

NS_ASSUME_NONNULL_BEGIN

@class CHWebImageView;

@protocol CHWebImageViewDelegate <NSObject>
- (void)webImageViewUpdated:(CHWebImageView *)imageView;
@end

@interface CHWebImageView : UIView<CHWebObjectItem>

@property (nonatomic, readonly, nullable, strong) UIImage *image;
@property (nonatomic, readonly, nullable, strong) NSString *fileURL;
@property (nonatomic, nullable, weak) id<CHWebImageViewDelegate> delegate;

- (nullable NSURL *)localFileURL;
- (void)loadFileURL:(nullable NSString *)fileURL expectedSize:(uint64_t)expectedSize;


@end

NS_ASSUME_NONNULL_END
