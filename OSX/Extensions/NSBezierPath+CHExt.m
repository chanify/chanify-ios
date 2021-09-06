//
//  NSBezierPath+CHExt.m
//  OSX
//
//  Created by WizJin on 2021/6/8.
//

#import "NSBezierPath+CHExt.h"
#import <objc/runtime.h>

@interface CHPath : NSObject
@property (nonatomic, nullable, assign) CGPathRef path;
@end

@implementation CHPath
- (instancetype)initWithCGPath:(CGPathRef)cgPath {
    if (self = [super init]) {
        self.path = cgPath;
    }
    return self;
}
- (void)dealloc {
    if (self.path != NULL) {
        CGPathRelease(self.path);
        self.path = NULL;
    }
}
@end

@implementation NSBezierPath (CHExt)

static const char *kCGPathTagKey = "CGPathTagKey";

+ (instancetype)bezierPathWithArcCenter:(CGPoint)center radius:(CGFloat)radius startAngle:(CGFloat)startAngle endAngle:(CGFloat)endAngle clockwise:(BOOL)clockwise {
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path appendBezierPathWithArcWithCenter:center radius:radius startAngle:startAngle*180.0*M_1_PI endAngle:endAngle*180.0*M_1_PI clockwise:clockwise];
    return path;
}

- (CGPathRef)CGPath {
    CHPath *chPath = objc_getAssociatedObject(self, kCGPathTagKey);
    CGPathRef res = chPath.path;
    if (res == NULL) {
        NSInteger n = self.elementCount;
        if (n > 0) {
            CGMutablePathRef path = CGPathCreateMutable();
            if (path != NULL) {
                NSPoint             pts[3];
                BOOL                bClose = YES;
                for (int i = 0; i < n; i++) {
                    switch ([self elementAtIndex:i associatedPoints:pts]) {
                        case NSBezierPathElementMoveTo:
                            CGPathMoveToPoint(path, NULL, pts[0].x, pts[0].y);
                            break;
                        case NSBezierPathElementLineTo:
                            CGPathAddLineToPoint(path, NULL, pts[0].x, pts[0].y);
                            bClose = NO;
                            break;
                        case NSBezierPathElementCurveTo:
                            CGPathAddCurveToPoint(path, NULL, pts[0].x, pts[0].y, pts[1].x, pts[1].y, pts[2].x, pts[2].y);
                            bClose = NO;
                            break;
                        case NSBezierPathElementClosePath:
                            CGPathCloseSubpath(path);
                            bClose = YES;
                            break;
                    }
                }
                res = CGPathCreateCopy(path);
                CGPathRelease(path);
                chPath = [[CHPath alloc] initWithCGPath:res];
                objc_setAssociatedObject(self, kCGPathTagKey, chPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
        }
    }
    return res;
}


@end
