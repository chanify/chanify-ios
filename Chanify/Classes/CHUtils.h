//
//  CHUtils.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#ifndef __CHUTILS_H__
#define __CHUTILS_H__

#ifdef __OBJC__

#pragma mark - Weakify & Strongify Macros
#if __has_feature(objc_arc)

#if DEBUG
#   define ext_keywordify       autoreleasepool {}
#else
#   define ext_keywordify       try {} @catch (...) {}
#endif

#define weakify(_x)                                     \
    ext_keywordify                                      \
    _Pragma("clang diagnostic push")                    \
    _Pragma("clang diagnostic ignored \"-Wshadow\"")    \
    __weak __typeof__(_x) __weak_##_x##__ = _x;         \
    _Pragma("clang diagnostic pop")

#define strongify(_x)                                   \
    ext_keywordify                                      \
    _Pragma("clang diagnostic push")                    \
    _Pragma("clang diagnostic ignored \"-Wshadow\"")    \
    __strong __typeof__(_x) _x = __weak_##_x##__;       \
    _Pragma("clang diagnostic pop")

#endif /* objc_arc */

#pragma mark - Dispatch Helper
#include <dispatch/queue.h>

dispatch_queue_t dispatch_queue_create_for(id obj, dispatch_queue_attr_t attr);

static inline void dispatch_main_async(dispatch_block_t block) {
    dispatch_async(dispatch_get_main_queue(), block);
}

static inline void dispatch_main_after(double delta, dispatch_block_t block) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delta * NSEC_PER_SEC)), dispatch_get_main_queue(), block);
}

#endif /* __OBJC__ */


#endif /* __CHUTILS_H__ */
