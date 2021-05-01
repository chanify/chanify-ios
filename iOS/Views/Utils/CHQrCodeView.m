//
//  CHQrCodeView.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHQrCodeView.h"

@implementation CHQrCodeView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = UIColor.whiteColor;
        self.layer.cornerRadius = 4.0;
        self.clipsToBounds = YES;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGSize size = self.bounds.size;
    if (!CGSizeEqualToSize(size, self.image.size)) {
        CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
        [filter setValue:[self.url dataUsingEncoding:NSASCIIStringEncoding] forKey:@"inputMessage"];
        // TODO: Set correction level
        // [filter setValue:@"M" forKey:@"inputCorrectionLevel"]; // L, M, Q, or H
        CIImage *image = filter.outputImage;
        if (image != nil) {
            CGRect extent = CGRectIntegral(image.extent);
            CGFloat scale = MIN(size.width/extent.size.width, size.height/extent.size.height);
            size_t with = scale * CGRectGetWidth(extent);
            size_t height = scale * CGRectGetHeight(extent);
            UIGraphicsBeginImageContext(CGSizeMake(with, height));
            CGContextRef imageContextRef = UIGraphicsGetCurrentContext();
            CIContext *context = [CIContext contextWithOptions:nil];
            CGImageRef outputImage = [context createCGImage:image fromRect:extent];
            CGContextSetInterpolationQuality(imageContextRef, kCGInterpolationNone);
            CGContextScaleCTM(imageContextRef, scale, scale);
            CGContextDrawImage(imageContextRef, extent, outputImage);
            self.image = UIGraphicsGetImageFromCurrentImageContext();
            CGImageRelease(outputImage);
            CGContextRelease(imageContextRef);
        }
    }
}

- (void)setUrl:(NSString *)url {
    if (![_url isEqualToString:url]) {
        _url = url;
        [self setNeedsLayout];
    }
}


@end
