//
//  CHMessagesHeaderView.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CHMessagesHeaderStatus) {
    CHMessagesHeaderStatusNormal     = 0,
    CHMessagesHeaderStatusLoading    = 1,
    CHMessagesHeaderStatusFinish     = 2,
};

@interface CHMessagesHeaderView : UICollectionReusableView

@property (nonatomic, assign) CHMessagesHeaderStatus status;


@end

NS_ASSUME_NONNULL_END
