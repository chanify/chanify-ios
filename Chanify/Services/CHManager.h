//
//  CHManager.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHManager<ObjectType> : NSObject

- (void)addDelegate:(ObjectType)delegate;
- (void)removeDelegate:(ObjectType)delegate;
- (void)sendNotifyWithSelector:(SEL)action;
- (void)sendNotifyWithSelector:(SEL)action withObject:(id)object;


@end

NS_ASSUME_NONNULL_END
