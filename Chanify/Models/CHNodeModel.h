//
//  CHNodeModel.h
//  Chanify
//
//  Created by WizJin on 2021/2/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, CHNodeModelFlags) {
    CHNodeModelFlagsNone            = 0,
    CHNodeModelFlagsStoreDevice     = 1 << 0,
};

@interface CHNodeModel : NSObject

@property (nonatomic, readonly, strong) NSString *nid;
@property (nonatomic, readonly, strong) NSString *name;
@property (nonatomic, readonly, strong) NSString *endpoint;
@property (nonatomic, nullable, strong) NSString *icon;
@property (nonatomic, assign) CHNodeModelFlags flags;
@property (nonatomic, readonly, strong) NSArray<NSString *> *features;

+ (instancetype)modelWithNID:(nullable NSString *)nid name:(nullable NSString *)name endpoint:(nullable NSString *)url flags:(CHNodeModelFlags)flags features:(nullable NSString *)features;
- (BOOL)isFullEqual:(CHNodeModel *)rhs;
- (NSURL *)apiURL;


@end

NS_ASSUME_NONNULL_END
