//
//  CHWidgetManager.h
//  WidgetsExtension
//
//  Created by WizJin on 2021/6/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHWidgetManager : NSObject

@property (class, nonatomic, readonly, strong) CHWidgetManager *shared;

- (BOOL)reloadDB;


@end

NS_ASSUME_NONNULL_END
