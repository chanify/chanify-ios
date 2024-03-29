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
#   define CHUIViewController                       NSViewController
#   define clipsToBounds                            chClipsToBounds
#   define layoutSubviews                           layout
#   define mas_safeLayoutGuideTop                   mas_top
#   define mas_safeLayoutGuideBottom                mas_bottom
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
#   define CHTextView                               NSTextView
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
#   import "CHProgressView.h"
#   import "CHSegmentedControl.h"
#   import "CHLineView.h"
#   import "CHMsgBubbleView.h"
#   import "CHMessageCellItem.h"
#   import "CHMenuController.h"
#   import "CHCollectionViewCell.h"
#   import "CHCollectionViewCellRegistration.h"
#   import "CHListContentConfiguration.h"
#   import "CHBarButtonItem.h"
#   import "CHFormViewCell.h"
#   import "CHAlertController.h"
#   import "NSColor+CHExt.h"
#else
#   import <UIKit/UIKit.h>
#   define tagID                                        tag
#   define CHImage                                      UIImage
#   define CHColor                                      UIColor
#   define CHView                                       UIView
#   define CHLineView                                   UIView
#   define CHMsgBubbleView                              UIView
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
#   define CHSegmentedControl                           UISegmentedControl
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
#   define CHTextView                                   UITextView
#   define viewWithTagID                                viewWithTag
#   define mas_safeLayoutGuideTop                       mas_safeAreaLayoutGuideTop
#   define mas_safeLayoutGuideBottom                    mas_safeAreaLayoutGuideBottom
#   import "UIColor+CHExt.h"
#endif

#endif /* __CHUI_H__ */
