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

@class CHSecKey;

@interface CHNodeModel : NSObject

@property (nonatomic, readonly, strong) NSString *nid;
@property (nonatomic, readonly, strong) NSString *name;
@property (nonatomic, readonly, strong) NSString *version;
@property (nonatomic, readonly, strong) NSString *endpoint;
@property (nonatomic, nullable, strong) NSData *pubkey;
@property (nonatomic, nullable, strong) NSString *icon;
@property (nonatomic, assign) CHNodeModelFlags flags;
@property (nonatomic, readonly, strong) NSArray<NSString *> *features;

+ (instancetype)modelWithNID:(nullable NSString *)nid name:(nullable NSString *)name version:(nullable NSString *)version endpoint:(nullable NSString *)url pubkey:(nullable NSData *)pubkey flags:(CHNodeModelFlags)flags features:(nullable NSString *)features;
+ (BOOL)verifyNID:(nullable NSString *)nid pubkey:(NSData *)pubkey;
- (void)setVersion:(nullable NSString *)version;
- (void)setEndpoint:(nullable NSString *)endpoint;
- (void)setFeatures:(nullable NSString *)features;
- (BOOL)isHigherVersion:(NSString *)version;
- (BOOL)isFullEqual:(CHNodeModel *)rhs;
- (nullable CHSecKey *)requestChiper;
- (NSURL *)apiURL;
- (BOOL)isStoreDevice;
- (BOOL)isSystem;


@end

NS_ASSUME_NONNULL_END
