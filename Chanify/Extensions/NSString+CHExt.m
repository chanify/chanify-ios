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

- (NSString *)localized {
    return [NSBundle.mainBundle localizedStringForKey:self value:@"" table:nil];
}

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


@end
