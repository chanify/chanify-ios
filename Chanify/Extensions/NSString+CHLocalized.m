//
//  NSString+CHLocalized.m
//  Chanify
//
//  Created by WizJin on 2021/3/26.
//

#import "NSString+CHLocalized.h"
#import <Foundation/Foundation.h>

@implementation NSString (CHLocalized)

- (NSString *)localized {
    return [NSBundle.mainBundle localizedStringForKey:self ?: @"" value:@"" table:nil];
}


@end
