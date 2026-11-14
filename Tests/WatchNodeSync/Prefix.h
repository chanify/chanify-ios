#import <Foundation/Foundation.h>
#import <TargetConditionals.h>
#undef TARGET_OS_WATCH
#define TARGET_OS_WATCH 1
#import "NSData+CHExt.h"
#import "NSString+CHExt.h"
#import "NSString+CHLocalized.h"
#import "NSFileManager+CHExt.h"
#define kCHAppWatchGroupName "test.invalid"
#define kCHAPIHostname "invalid.example"
#define kCHNodeCanCipherVersion "1.0"
#define weakify(obj) autoreleasepool {} __weak typeof(obj) weak_##obj = obj
#define strongify(obj) autoreleasepool {} __strong typeof(obj) obj = weak_##obj
static inline void dispatch_main_async(dispatch_block_t block) { dispatch_async(dispatch_get_main_queue(), block); }
