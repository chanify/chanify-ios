//
//  CHLoadMoreView.h
//  iOS
//
//  Created by WizJin on 2021/5/25.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CHLoadStatus) {
    CHLoadStatusNormal  = 0,
    CHLoadStatusLoading = 1,
    CHLoadStatusFinish  = 2,
};

@interface CHLoadMoreView : UICollectionReusableView

@property (nonatomic, assign) CHLoadStatus status;


@end

NS_ASSUME_NONNULL_END
