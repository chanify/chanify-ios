//
//  CHScrollView.h
//  OSX
//
//  Created by WizJin on 2021/6/10.
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CHScrollView;

@protocol CHScrollViewDelegate <NSObject>
@optional
- (void)scrollViewDidScroll:(CHScrollView *)scrollView;
@end

@interface CHScrollView : NSScrollView

@property (nonatomic, nullable, weak) id<CHScrollViewDelegate> delegate;


@end

NS_ASSUME_NONNULL_END
