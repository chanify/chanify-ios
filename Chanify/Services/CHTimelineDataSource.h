//
//  CHTimelineDataSource.h
//  iOS
//
//  Created by WizJin on 2021/8/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHTimelineDataSource : NSObject

+ (instancetype)dataSourceWithURL:(NSURL *)url;
- (void)close;
- (void)flush;


@end

NS_ASSUME_NONNULL_END
