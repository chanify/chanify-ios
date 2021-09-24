//
//  CHFormViewPage.h
//  iOS
//
//  Created by WizJin on 2021/9/24.
//


#ifndef __CHFORMVIEWPAGE_H__
#define __CHFORMVIEWPAGE_H__

#if TARGET_OS_OSX
#   import "CHFormView.h"
#   define CHFormViewPage   CHFormView
#else
#   import "CHFormViewController.h"
#   define CHFormViewPage   CHFormViewController
#endif

#endif // __CHFORMVIEWPAGE_H__
