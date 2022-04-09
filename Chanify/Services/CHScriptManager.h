//
//  CHScriptManager.h
//  Chanify
//
//  Created by WizJin on 2022/4/1.
//

#import "CHManager.h"

NS_ASSUME_NONNULL_BEGIN

@class CHUserDataSource;

@interface CHScriptManager : NSObject

@property (nonatomic, readonly, strong) NSString *uid;

+ (instancetype)scriptManagerWithUID:(NSString *)uid datasource:(CHUserDataSource *)ds;
- (void)close;


@end

NS_ASSUME_NONNULL_END
