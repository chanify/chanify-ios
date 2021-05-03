//
//  CHImage.h
//  iOS
//
//  Created by WizJin on 2021/5/3.
//

#if __has_include(<AppKit/AppKit.h>)
#   import <AppKit/NSImage.h>
#   define CHImage  NSImage
#else
#   import <UIKit/UIImage.h>
#   define CHImage  UIImage
#endif
