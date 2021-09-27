//
//  CHIconManager.h
//  Chanify
//
//  Created by WizJin on 2021/9/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHIconManager : NSObject

@property (nonatomic, readonly, strong) NSArray<NSString *> *icons;
@property (nonatomic, readonly, strong) NSArray<NSString *> *colors;
@property (nonatomic, readonly, strong) NSArray<NSString *> *backgroundColors;

+ (instancetype)shared;


@end

NS_ASSUME_NONNULL_END
