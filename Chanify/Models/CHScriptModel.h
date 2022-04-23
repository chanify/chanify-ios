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
@property (nonatomic, readwrite, strong) NSDate *lastupdate;
@property (nonatomic, nullable, strong) NSString *content;

+ (instancetype)modelWithName:(NSString *)name type:(NSString *)type lastupdate:(NSDate *)lastupdate;


@end

NS_ASSUME_NONNULL_END
