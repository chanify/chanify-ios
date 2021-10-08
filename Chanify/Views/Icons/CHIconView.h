//
//  CHIconView.h
//  Chanify
//
//  Created by WizJin on 2021/3/7.
//

#import "CHUI.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHIconView : CHView

@property (nonatomic, strong) NSString *image;

- (CHImage *)saveImage API_UNAVAILABLE(macos, tvos);


@end

NS_ASSUME_NONNULL_END
