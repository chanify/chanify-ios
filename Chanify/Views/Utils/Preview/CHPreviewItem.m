//
//  CHPreviewItem.m
//  Chanify
//
//  Created by WizJin on 2021/3/30.
//

#import "CHPreviewItem.h"

#define kCHImageHeaderBytes 12

static const uint8_t gifHdr[] = { 'G', 'I', 'F' };
static const uint8_t pngHdr[] = { 0x89, 'P', 'N', 'G', '\r', '\n', 0x1a, '\n' };

@implementation CHPreviewItem

+ (instancetype)itemWithURL:(NSURL *)url title:(NSString *)title uti:(NSString *)uti {
    return [[self.class alloc] initWithURL:url title:title uti:uti];
}

+ (nullable NSURL *)imageFileSharedURL:(nullable NSURL *)url {
    if (url != nil) {
        NSArray *items = [detectImageUTI(url) componentsSeparatedByString:@"."];
        if (items.count > 0) {
            NSString *filename = [NSString stringWithFormat:@"%@.%@", @"ImageFile".localized, items.lastObject];
            url = [NSFileManager.defaultManager URLLinkForFile:url withName:filename];
        }
    }
    return url;
}

- (instancetype)initWithURL:(NSURL *)url title:(NSString *)title uti:(NSString *)uti {
    if (self = [super init]) {
        _previewItemTitle = title;
        _previewItemURL = url;
        _previewItemContentType = detectImageUTI(url);
    }
    return self;
}

#pragma mark - Private Methods
static inline NSString *detectImageUTI(NSURL *url) {
    NSString *uti = @"public.jpeg";
    if (url.isFileURL) {
        FILE *fp = fopen(url.path.cstr, "rb");
        if (fp != NULL) {
            uint8_t header[kCHImageHeaderBytes] = { 0 };
            fread(header, 1, sizeof(header), fp);
            fclose(fp);
            if (memcmp(header, gifHdr, sizeof(gifHdr)) == 0) {
                uti = @"com.compuserve.gif";
            } else if (memcmp(header, pngHdr, sizeof(pngHdr)) == 0) {
                uti = @"public.png";
            } else if (*(uint16_t *)header == 0x4949 || *(uint16_t *)header == 0x4D4D) {
                uti = @"public.tiff";
            } else if (((uint32_t *)header)[0] == *(uint32_t *)"RIFF" && ((uint32_t *)header)[2] == *(uint32_t *)"WEBP") {
                uti = @"org.webmproject.webp";
            }
        }
    }
    return uti;
}


@end
