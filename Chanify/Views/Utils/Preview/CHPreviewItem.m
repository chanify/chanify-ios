//
//  CHPreviewItem.m
//  Chanify
//
//  Created by WizJin on 2021/3/30.
//

#import "CHPreviewItem.h"

static const uint8_t gifHdr[] = { 'G', 'I', 'F' };
static const uint8_t pngHdr[] = { 0x89, 'P', 'N', 'G', '\r', '\n', 0x1a, '\n' };

@implementation CHPreviewItem

+ (instancetype)itemWithURL:(NSURL *)url title:(NSString *)title uti:(NSString *)uti {
    return [[self.class alloc] initWithURL:url title:title uti:uti];
}

- (instancetype)initWithURL:(NSURL *)url title:(NSString *)title uti:(NSString *)uti {
    if (self = [super init]) {
        if ([uti isEqualToString:@"image"]) {
            uti = @"public.jpeg";
            if (url.isFileURL) {
                FILE *fp = fopen(url.path.cstr, "rb");
                if (fp != NULL) {
                    uint8_t header[sizeof(pngHdr)] = { 0 };
                    fread(header, 1, sizeof(header), fp);
                    fclose(fp);
                    if (memcmp(header, gifHdr, sizeof(gifHdr)) == 0) {
                        uti = @"com.compuserve.gif";
                    } else if (memcmp(header, pngHdr, sizeof(pngHdr)) == 0) {
                        uti = @"public.png";
                    }
                }
            }
        }
        _previewItemTitle = title;
        _previewItemURL = url;
        _previewItemContentType = uti;
    }
    return self;
}


@end
