#import <Foundation/Foundation.h>
#import <TargetConditionals.h>
#import "NSString+CHLocalized.h"
#undef TARGET_OS_WATCH
#define TARGET_OS_WATCH CH_TEST_WATCH
#define weakify(obj) autoreleasepool {} __weak typeof(obj) weak_##obj = obj
#define strongify(obj) autoreleasepool {} __strong typeof(obj) obj = weak_##obj
static inline void dispatch_main_async(dispatch_block_t block) { dispatch_async(dispatch_get_main_queue(), block); }
