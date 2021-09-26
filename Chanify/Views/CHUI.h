//
//  CHUI.h
//  Chanify
//
//  Created by WizJin on 2021/6/2.
//

#ifndef __CHUI_H__
#define __CHUI_H__

#if TARGET_OS_OSX
#   define CHImage                                  NSImage
#   define CHColor                                  NSColor
#   define CHView                                   NSView
#   define CHFont                                   NSFont
#   define CHScreen                                 NSScreen
#   define CHImageView                              NSImageView
#   define CHEdgeInsets                             NSEdgeInsets
#   define CHButton                                 NSButton
#   define CHMenuItem                               NSMenuItem
#   define CHBezierPath                             NSBezierPath
#   define CHProgressView                           NSProgressIndicator
#   define CHUIViewController                       NSViewController
#   define CHNodeViewController                     CHNodeViewPage
#   define clipsToBounds                            chClipsToBounds
#   define layoutSubviews                           layout
#   define CHGestureRecognizer                      NSGestureRecognizer
#   define UIGraphicsGetCurrentContext()            (NSGraphicsContext.currentContext.CGContext)
#   define UIViewContentModeScaleAspectFill         NSImageScaleAxesIndependently
#   define UIViewContentModeScaleAspectFit          NSImageScaleProportionallyUpOrDown
#   define UIViewContentModeCenter                  NSImageScaleProportionallyDown
#   define UIFontWeightRegular                      NSFontWeightRegular
#   define UIProgressViewStyleBar                   NSProgressIndicatorStyleBar
#   define UICollectionReusableView                 NSView
#   define UIViewPropertyAnimator                   NSAnimationContext
#   define UIViewAnimatingPosition                  NSInteger
#   define UIViewAnimationOptionCurveEaseIn         0
#   define UIViewAnimationOptionCurveEaseOut        1

typedef NS_OPTIONS(NSUInteger, CHControlEvents) {
    CHControlEventValueChanged  = 1,
};

#   import "NSView+CHExt.h"
#   import "NSScreen+CHExt.h"
#   import "CHLabel.h"
#   import "CHSwitch.h"
#   import "CHDatePicker.h"
#   import "CHLineView.h"
#   import "CHMessageCellItem.h"
#   import "CHMenuController.h"
#   import "CHCollectionViewCell.h"
#   import "CHCollectionViewCellRegistration.h"
#   import "CHListContentConfiguration.h"
#   import "CHBarButtonItem.h"
#   import "CHFormViewCell.h"
#   import "CHAlertController.h"
#else
#   import <UIKit/UIKit.h>
#   define CHImage                                      UIImage
#   define CHColor                                      UIColor
#   define CHView                                       UIView
#   define CHLineView                                   UIView
#   define CHFont                                       UIFont
#   define CHScreen                                     UIScreen
#   define CHLabel                                      UILabel
#   define CHImageView                                  UIImageView
#   define CHEdgeInsets                                 UIEdgeInsets
#   define CHButton                                     UIButton
#   define CHSwitch                                     UISwitch
#   define CHDatePicker                                 UIDatePicker
#   define CHDatePickerModeDate                         UIDatePickerModeDate
#   define CHDatePickerStyleCompact                     UIDatePickerStyleCompact
#   define CHMenuItem                                   UIMenuItem
#   define CHBarButtonItem                              UIBarButtonItem
#   define CHBezierPath                                 UIBezierPath
#   define CHProgressView                               UIProgressView
#   define CHContentView                                UIContentView
#   define CHUIViewController                           UIViewController
#   define CHAlertController                            UIAlertController
#   define CHCollectionViewCell                         UICollectionViewCell
#   define CHContentConfiguration                       UIContentConfiguration
#   define CHConfigurationState                         UIConfigurationState
#   define CHCellConfigurationState                     UICellConfigurationState
#   define CHCollectionViewCellRegistration             UICollectionViewCellRegistration
#   define CHGestureRecognizer                          UIGestureRecognizer
#   define CHTapGestureRecognizer                       UITapGestureRecognizer
#   define CHLongPressGestureRecognizer                 UILongPressGestureRecognizer
#   define CHMenuController                             UIMenuController
#   define CHListContentView                            UIListContentView
#   define CHListContentConfiguration                   UIListContentConfiguration
#   define CHListContentTextAlignmentCenter             UIListContentTextAlignmentCenter
#   define CHFormViewCell                               UITableViewCell
#   define CHFormViewCellAccessoryType                  UITableViewCellAccessoryType
#   define CHFormViewCellAccessoryNone                  UITableViewCellAccessoryNone
#   define CHFormViewCellAccessoryDisclosureIndicator   UITableViewCellAccessoryDisclosureIndicator
#   define CHControlEventValueChanged                   UIControlEventValueChanged
#endif

#endif /* __CHUI_H__ */
