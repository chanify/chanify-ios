//
//  NSFont+CHExt.m
//  OSX
//
//  Created by WizJin on 2021/6/8.
//

#import "NSFont+CHExt.h"

@implementation NSFont (CHExt)

+ (instancetype)italicSystemFontOfSize:(CGFloat)fontSize {
    NSFontManager *fontManager = NSFontManager.sharedFontManager;
    return [fontManager fontWithFamily:[NSFont systemFontOfSize:fontSize].familyName traits:NSItalicFontMask weight:0 size:fontSize];
}


@end
