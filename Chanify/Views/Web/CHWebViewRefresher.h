//
//  CHWebViewRefresher.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHWebViewRefresher : UIRefreshControl

@property (nonatomic, strong) NSString *host;
@property (nonatomic, assign) BOOL hasOnlySecureContent;


@end

NS_ASSUME_NONNULL_END
