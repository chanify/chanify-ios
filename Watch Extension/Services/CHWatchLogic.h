//
//  CHWatchLogic.h
//  Watch Extension
//
//  Created by WizJin on 2021/4/19.
//

#import <WatchConnectivity/WatchConnectivity.h>
#import "CHManager.h"
#import "CHUserModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHWatchLogic : NSObject<WCSessionDelegate>

@property (nonatomic, readonly, strong) WCSession *session;
@property (nonatomic, readonly, nullable, strong) CHUserModel *me;

- (void)onUpdateUserInfo;


@end

NS_ASSUME_NONNULL_END
