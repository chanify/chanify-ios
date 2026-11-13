#import <Foundation/Foundation.h>
#import <TargetConditionals.h>
#import "NSData+CHExt.h"
#import "NSString+CHExt.h"
#import "NSURL+CHExt.h"
#undef TARGET_OS_WATCH
#define TARGET_OS_WATCH 1
#define kCHDBFileProtectionFlags 0
#define CHLogI(...) ((void)0)
#define NSURLFileProtectionCompleteUntilFirstUserAuthentication @"synthetic-protection"
static inline void dispatch_main_async(dispatch_block_t block) { dispatch_async(dispatch_get_main_queue(), block); }
