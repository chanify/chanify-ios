//
//  CHWebImageView.h
//  Chanify
//
//  Created by WizJin on 2021/3/27.
//

#import <UIKit/UIKit.h>
#import "CHWebFileManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHWebImageView : UIImageView<CHWebFileItem>

@property (nonatomic, nullable, strong) NSString *fileURL;


@end

NS_ASSUME_NONNULL_END
