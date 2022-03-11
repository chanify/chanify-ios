//
//  UIImage+CHExt.m
//  iOS
//
//  Created by WizJin on 2022/3/10.
//

#import "UIImage+CHExt.h"
#import <ImageIO/ImageIO.h>

@implementation UIImage (CHExt)

+ (nullable instancetype)imageWithAnimatedData:(NSData *)data {
    if (data.length > 0) {
        const uint8_t *ptr = data.bytes;
        if (ptr[0] == 'G' && ptr[1] == 'I' && ptr[2] == 'F') {
            UIImage *image = createGIFImageWithData(data);
            if (image != nil) {
                return image;
            }
        }
    }
    return [UIImage imageWithData:data];
}

#pragma mark - GIF Helper
static UIImage *createGIFImageWithData(NSData *data) {
    UIImage *image = nil;
    CGImageSourceRef pSource = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    if (pSource != NULL) {
        size_t const count = CGImageSourceGetCount(pSource);
        CGImageRef images[count];
        int delayCentiseconds[count];
        createImagesAndDelays(pSource, count, images, delayCentiseconds);
        int const totalDurationCentiseconds = sum(count, delayCentiseconds);
        NSArray *const frames = frameArray(count, images, delayCentiseconds, totalDurationCentiseconds);
        image = [UIImage animatedImageWithImages:frames duration:(NSTimeInterval)totalDurationCentiseconds / 100.0];
        releaseImages(count, images);
        CFRelease(pSource);
    }
    return image;
}

static int delayCentisecondsForImageAtIndex(CGImageSourceRef const source, size_t const i) {
    int delayCentiseconds = 1;
    CFDictionaryRef const properties = CGImageSourceCopyPropertiesAtIndex(source, i, NULL);
    if (properties) {
        CFDictionaryRef const gifProperties = CFDictionaryGetValue(properties, kCGImagePropertyGIFDictionary);
        if (gifProperties) {
            NSNumber *number = CFDictionaryGetValue(gifProperties, kCGImagePropertyGIFUnclampedDelayTime);
            if (number == NULL || [number doubleValue] == 0) {
                number = CFDictionaryGetValue(gifProperties, kCGImagePropertyGIFDelayTime);
            }
            if ([number doubleValue] > 0) {
                // Even though the GIF stores the delay as an integer number of centiseconds, ImageIO “helpfully” converts that to seconds for us.
                delayCentiseconds = (int)lrint([number doubleValue] * 100);
            }
        }
        CFRelease(properties);
    }
    return delayCentiseconds;
}

static void createImagesAndDelays(CGImageSourceRef source, size_t count, CGImageRef imagesOut[count], int delayCentisecondsOut[count]) {
    for (size_t i = 0; i < count; ++i) {
        imagesOut[i] = CGImageSourceCreateImageAtIndex(source, i, NULL);
        delayCentisecondsOut[i] = delayCentisecondsForImageAtIndex(source, i);
    }
}

static int sum(size_t const count, int const *const values) {
    int theSum = 0;
    for (size_t i = 0; i < count; ++i) {
        theSum += values[i];
    }
    return theSum;
}

static int pairGCD(int a, int b) {
    if (a < b)
        return pairGCD(b, a);
    while (true) {
        int const r = a % b;
        if (r == 0)
            return b;
        a = b;
        b = r;
    }
}

static int vectorGCD(size_t const count, int const *const values) {
    int gcd = values[0];
    for (size_t i = 1; i < count; ++i) {
        // Note that after I process the first few elements of the vector, `gcd` will probably be smaller than any remaining element.  By passing the smaller value as the second argument to `pairGCD`, I avoid making it swap the arguments.
        gcd = pairGCD(values[i], gcd);
    }
    return gcd;
}

static NSArray *frameArray(size_t const count, CGImageRef const images[count], int const delayCentiseconds[count], int const totalDurationCentiseconds) {
    int const gcd = vectorGCD(count, delayCentiseconds);
    size_t const frameCount = totalDurationCentiseconds / gcd;
    UIImage *frames[frameCount];
    for (size_t i = 0, f = 0; i < count; ++i) {
        UIImage *const frame = [UIImage imageWithCGImage:images[i]];
        for (size_t j = delayCentiseconds[i] / gcd; j > 0; --j) {
            frames[f++] = frame;
        }
    }
    return [NSArray arrayWithObjects:frames count:frameCount];
}

static void releaseImages(size_t const count, CGImageRef const images[count]) {
    for (size_t i = 0; i < count; ++i) {
        CGImageRelease(images[i]);
    }
}


@end
