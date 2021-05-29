//
//  NSNumber+CHExt.m
//  Chanify
//
//  Created by WizJin on 2021/4/14.
//

#import "NSNumber+CHExt.h"
#import <math.h>

@implementation NSNumber (CHExt)

- (NSString *)formatFileSize {
    static const char *units[] = { "B", "KB", "MB", "GB", "TB" };
    uint64_t size = [self unsignedLongLongValue];
    if (size <= 0) return @"0";
    int idx = (int)(log10(size)/log10(1000));
    idx = MIN(MAX(idx, 0), (int)(sizeof(units)/sizeof(units[0])) - 1);
    return [NSString stringWithFormat:@"%.1f%s", size/pow(1000, idx), units[idx]];
}

- (NSString *)formatDuration {
    uint64_t duration = [self unsignedLongLongValue];
    uint64_t ms = duration/1000 + (duration%1000 >= 500 ? 1 : 0);
    NSString *prefix = @"";
    if (ms >= 3600) {
        prefix = [NSString stringWithFormat:@"%llu:", ms/3600];
        ms %= 3600;
    }
    return [NSString stringWithFormat:@"%@%02llu:%02llu", prefix, ms/60, ms%60];
}


@end
