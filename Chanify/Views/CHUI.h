//
//  CHUI.h
//  Chanify
//
//  Created by WizJin on 2021/6/2.
//

#ifndef __CHUI_H__
#define __CHUI_H__

#if TARGET_OS_OSX
#   import "NSView+CHExt.h"
#   define CHImage  NSImage
#   define CHColor  NSColor
#   define CHView   NSView
#   define CHFont   NSFont
#   define CHUIViewController   NSViewController
#   define clipsToBounds        chClipsToBounds
#   define layoutSubviews       layout
#   define UIGraphicsGetCurrentContext()    (NSGraphicsContext.currentContext.CGContext)
#else
#   import <UIKit/UIKit.h>
#   define CHImage  UIImage
#   define CHColor  UIColor
#   define CHView   UIView
#   define CHFont   UIFont
#   define CHUIViewController   UIViewController
#endif

#endif /* __CHUI_H__ */
