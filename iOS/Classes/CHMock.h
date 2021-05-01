//
//  CHMock.h
//  Chanify
//
//  Created by WizJin on 2021/2/9.
//

#ifndef __CHMOCK_H__
#define __CHMOCK_H__

#include <Foundation/Foundation.h>

// Mock notificaton for simulator
#if !(TARGET_OS_SIMULATOR)
#   define try_mock_notification(x)    (x)
#else
#import <Foundation/Foundation.h>
NSDictionary *try_mock_notification(NSDictionary* info);

#endif /* TARGET_IPHONE_SIMULATOR */

#endif /* __CHMOCK_H__ */
