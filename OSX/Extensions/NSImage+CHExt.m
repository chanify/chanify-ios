//
//  NSImage+CHExt.m
//  OSX
//
//  Created by WizJin on 2021/5/3.
//

#import "NSImage+CHExt.h"

@implementation NSImage (CHExt)

+ (instancetype)systemImageNamed:(NSString *)name {
    return [NSImage imageWithSystemSymbolName:name accessibilityDescription:name];
}

+ (nullable instancetype)imageWithData:(NSData *)data {
    if (data.length > 0) {
        return [[NSImage alloc] initWithData:data];
    }
    return nil;
}

- (NSImage *)imageWithTintColor:(NSColor *)color {
    NSImage *image = self;
    if (image.isTemplate) {
        NSImage *img = [image copy];
        if (img != nil) {
            [img lockFocus];
            NSRect rc = NSMakeRect(0, 0, img.size.width, img.size.height);
            [color set];
            NSRectFillUsingOperation(rc, NSCompositingOperationSourceIn);
            [img unlockFocus];
            img.template = NO;
            image = img;
        }
    }
    return image;
}


@end
