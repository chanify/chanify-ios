//
//  CHSoundManager.h
//  iOS
//
//  Created by WizJin on 2022/3/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHSoundManager : NSObject

+ (instancetype)soundManagerWithGroupId:(NSString *)groupId;
- (void)playWithName:(NSString *)name;
- (NSArray<NSString *> *)soundNames;


@end

NS_ASSUME_NONNULL_END
