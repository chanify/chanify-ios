//
//  NSURL+CHExt.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "NSURL+CHExt.h"

@implementation NSURL (CHExt)

- (void)setDataProtoction:(NSString *)level {
    if (self.fileURL) {
        NSString *value = nil;
        if (![self getResourceValue:&value forKey:NSURLFileProtectionKey error:nil] || ![value isEqualToString:level]) {
            NSError *error = nil;
            [self setResourceValues:@{ NSURLFileProtectionKey: level } error:&error];
            if (error != nil) {
                CHLogE("Change file data protoction failed: %s", error.description.cstr);
            }
        }
    }
}

- (uint64_t)fileSize {
    uint64_t size = 0;
    if (self != nil) {
        NSNumber *val = nil;
        if ([self getResourceValue:&val forKey:NSURLFileSizeKey error:nil]) {
            size = [val unsignedLongLongValue];
        }
        
    }
    return size;
}


@end
