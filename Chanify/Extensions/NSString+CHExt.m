//
//  NSString+CHExt.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "NSString+CHExt.h"
#import <Foundation/NSBundle.h>
#import <ctype.h>

@implementation NSString (CHExt)

- (NSString *)code {
    NSString *name = self;
    NSUInteger length = self.length;
    if (length > 0) {
        unichar *ptr = malloc(sizeof(unichar) * length);
        if (ptr != NULL) {
            int n = 0;
            BOOL upper = YES;
            const char *s = self.UTF8String;
            for (int i = 0; i < length; i++) {
                char c = s[i];
                if (c == '_' || c == '-') {
                    upper = YES;
                    continue;
                }
                if (upper) {
                    c = toupper(c);
                    upper = NO;
                }
                ptr[n++] = c;
            }
            name = [[NSString alloc] initWithCharactersNoCopy:ptr length:n freeWhenDone:YES];
        }
    }
    return name;
}

- (const char *)cstr {
    if (self != nil) {
        const char *ptr = [self cStringUsingEncoding:NSASCIIStringEncoding];
        if (ptr != NULL) {
            return ptr;
        }
    }
    return "";
}

- (uint64_t)uint64Hex {
    NSUInteger len = self.length;
    if (len > 0) {
        uint64_t x = 0;
        len = MIN(len, 16);
        for (NSUInteger i = 0; i < len; i++) {
            unichar c = [self characterAtIndex:i];
            switch (c) {
                case '0':case '1':case '2':case '3':case '4':case '5':case '6':case '7':case '8':case '9':
                    x <<= 4;
                    x |= c - '0';
                    continue;
                case 'a':case 'b':case 'c':case 'd':case 'e':case 'f':
                    x <<= 4;
                    x |= c - 'a' + 10;
                    continue;
                case 'A':case 'B':case 'C':case 'D':case 'E':case 'F':
                    x <<= 4;
                    x |= c - 'A' + 10;
                    continue;
            }
            break;
        }
        return x;
    }
    return 0;
}

- (BOOL)compareAsVersion:(nullable NSString *)rhs {
    BOOL res = NO;
    if (self.length > 0 && rhs.length > 0) {
        NSArray<NSString *> *v1 = [self componentsSeparatedByString:@"."];
        NSArray<NSString *> *v2 = [rhs componentsSeparatedByString:@"."];
        if (v1.count >= 3 && v2.count >= 3) {
            res = YES;
            for (int i = 0; i < 3; i++){
                if ([[v1 objectAtIndex:i] integerValue] < [[v2 objectAtIndex:i] integerValue]) {
                    res = NO;
                    break;
                }
            }
        }
    }
    return res;
}


@end
