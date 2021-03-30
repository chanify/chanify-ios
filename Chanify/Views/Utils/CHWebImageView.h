//
//  CHWebImageView.h
//  Chanify
//
//  Created by WizJin on 2021/3/27.
//

#import <UIKit/UIKit.h>
#import "CHWebFileManager.h"

NS_ASSUME_NONNULL_BEGIN

@class CHWebImageView;

@protocol CHWebImageViewDelegate <NSObject>
- (void)webImageViewUpdated:(CHWebImageView *)imageView;
@end

@interface CHWebImageView : UIImageView<CHWebFileItem>

@property (nonatomic, nullable, strong) NSString *fileURL;
@property (nonatomic, nullable, weak) id<CHWebImageViewDelegate> delegate;

- (nullable NSURL *)localFileURL;


@end

NS_ASSUME_NONNULL_END
