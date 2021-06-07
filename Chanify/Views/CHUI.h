//
//  CHUI.h
//  Chanify
//
//  Created by WizJin on 2021/6/2.
//

#ifndef __CHUI_H__
#define __CHUI_H__

#if TARGET_OS_OSX
#   define CHImage                          NSImage
#   define CHColor                          NSColor
#   define CHView                           NSView
#   define CHFont                           NSFont
#   define CHScreen                         NSScreen
#   define CHImageView                      NSImageView
#   define CHEdgeInsets                     NSEdgeInsets
#   define CHButton                         NSButton
#   define CHMenuItem                       NSMenuItem
#   define CHUIViewController               NSViewController
#   define clipsToBounds                    chClipsToBounds
#   define layoutSubviews                   layout
#   define CHGestureRecognizer              NSGestureRecognizer
#   define UIGraphicsGetCurrentContext()    (NSGraphicsContext.currentContext.CGContext)
#   import "NSView+CHExt.h"
#   import "NSScreen+CHExt.h"
#   import "CHLabel.h"
#   import "CHMessageCellItem.h"
#   import "CHCollectionViewCell.h"
#   import "CHCollectionViewCellRegistration.h"
#else
#   import <UIKit/UIKit.h>
#   define CHImage                          UIImage
#   define CHColor                          UIColor
#   define CHView                           UIView
#   define CHFont                           UIFont
#   define CHScreen                         UIScreen
#   define CHLabel                          UILabel
#   define CHImageView                      UIImageView
#   define CHEdgeInsets                     UIEdgeInsets
#   define CHButton                         UIButton
#   define CHMenuItem                       UIMenuItem
#   define CHContentView                    UIContentView
#   define CHUIViewController               UIViewController
#   define CHCollectionViewCell             UICollectionViewCell
#   define CHContentConfiguration           UIContentConfiguration
#   define CHConfigurationState             UIConfigurationState
#   define CHCellConfigurationState         UICellConfigurationState
#   define CHCollectionViewCellRegistration UICollectionViewCellRegistration
#   define CHGestureRecognizer              UIGestureRecognizer
#   define CHTapGestureRecognizer           UITapGestureRecognizer
#   define CHLongPressGestureRecognizer     UILongPressGestureRecognizer
#   define CHMenuController                 UIMenuController
#endif

#endif /* __CHUI_H__ */
