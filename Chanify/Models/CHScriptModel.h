//
//  CHScriptModel.h
//  Chanify
//
//  Created by WizJin on 2022/4/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHScriptModel : NSObject

@property (nonatomic, readonly, strong) NSString *name;
@property (nonatomic, readonly, strong) NSString *type;
@property (nonatomic, readonly, strong) NSDate *lastmodify;


@end

NS_ASSUME_NONNULL_END
