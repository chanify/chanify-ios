//
//  CHNodeModel.h
//  Chanify
//
//  Created by WizJin on 2021/2/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHNodeModel : NSObject

@property (nonatomic, readonly, strong) NSString *nid;
@property (nonatomic, readonly, strong) NSString *name;
@property (nonatomic, readonly, strong) NSString *url;
@property (nonatomic, nullable, strong) NSString *icon;

+ (instancetype)modelWithNID:(nullable NSString *)nid name:(nullable NSString *)name url:(nullable NSString *)url;


@end

NS_ASSUME_NONNULL_END
