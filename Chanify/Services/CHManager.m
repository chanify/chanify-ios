//
//  CHManager.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHManager.h"

@interface CHManager<ObjectType> ()

@property (nonatomic, readonly, strong) NSHashTable<ObjectType> *delegates;

@end

@implementation CHManager

- (instancetype)init {
    if (self = [super init]) {
        _delegates = [NSHashTable weakObjectsHashTable];
    }
    return self;
}

- (void)addDelegate:(id)delegate {
    [self.delegates addObject:delegate];
}

- (void)removeDelegate:(id)delegate {
    [self.delegates removeObject:delegate];
}

- (void)sendNotifyWithSelector:(SEL)action {
    @weakify(self);
    dispatch_main_async(^{
        @strongify(self);
        for (id delegate in self.delegates) {
            if ([delegate respondsToSelector:action]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [delegate performSelector:action];
#pragma clang diagnostic pop
            }
        }
    });
}

- (void)sendNotifyWithSelector:(SEL)action withObject:(id)object {
    @weakify(self);
    dispatch_main_async(^{
        @strongify(self);
        for (id delegate in self.delegates) {
            if ([delegate respondsToSelector:action]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [delegate performSelector:action withObject:object];
#pragma clang diagnostic pop
            }
        }
    });
}


@end
