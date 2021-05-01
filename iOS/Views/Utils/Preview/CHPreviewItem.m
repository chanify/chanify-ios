//
//  CHPreviewItem.m
//  Chanify
//
//  Created by WizJin on 2021/3/30.
//

#import "CHPreviewItem.h"

@implementation CHPreviewItem

+ (instancetype)itemWithURL:(NSURL *)url title:(NSString *)title uti:(NSString *)uti {
    return [[self.class alloc] initWithURL:url title:title uti:uti];
}

- (instancetype)initWithURL:(NSURL *)url title:(NSString *)title uti:(NSString *)uti {
    if (self = [super init]) {
        _previewItemTitle = title;
        _previewItemURL = url;
        _previewItemContentType = uti;
    }
    return self;
}


@end
