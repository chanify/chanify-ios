//
//  CHViewPage.h
//  Chanify
//
//  Created by WizJin on 2021/9/27.
//

#ifndef __CHVIEWPAGE_H__
#define __CHVIEWPAGE_H__

#if TARGET_OS_OSX
#   import "CHPageView.h"
#   define CHViewPage     CHPageView
#else
#   import "CHViewController.h"
#   define CHViewPage     CHViewController
#endif

#endif // __CHVIEWPAGE_H__
