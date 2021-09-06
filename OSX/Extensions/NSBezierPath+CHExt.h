//
//  NSBezierPath+CHExt.h
//  OSX
//
//  Created by WizJin on 2021/6/8.
//

#import <AppKit/NSBezierPath.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSBezierPath (CHExt)

+ (instancetype)bezierPathWithArcCenter:(CGPoint)center radius:(CGFloat)radius startAngle:(CGFloat)startAngle endAngle:(CGFloat)endAngle clockwise:(BOOL)clockwise;
- (CGPathRef)CGPath NS_RETURNS_INNER_POINTER;


@end

NS_ASSUME_NONNULL_END
