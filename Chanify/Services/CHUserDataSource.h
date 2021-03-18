//
//  CHUserDataSource.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CHNodeModel;
@class CHChannelModel;
@class CHMessageModel;
@protocol CHKeyStorage;

@interface CHUserDataSource : NSObject

@property (nonatomic, readonly, strong) NSURL *dsURL;
@property (nonatomic, nullable, strong) NSData *srvkey;

+ (instancetype)dataSourceWithURL:(NSURL *)url;
- (void)close;
- (BOOL)insertNode:(CHNodeModel *)model secret:(NSData *)secret;
- (BOOL)updateNode:(CHNodeModel *)model;
- (BOOL)deleteNode:(nullable NSString *)nid;
- (nullable NSData *)keyForNodeID:(nullable NSString *)nid;
- (NSArray<CHNodeModel *> *)loadNodes;
- (nullable CHNodeModel *)nodeWithNID:(nullable NSString *)nid;
- (BOOL)insertChannel:(CHChannelModel *)model;
- (BOOL)updateChannel:(CHChannelModel *)model;
- (BOOL)deleteChannel:(nullable NSString *)cid;
- (NSArray<CHChannelModel *> *)loadChannels;
- (nullable CHChannelModel *)channelWithCID:(nullable NSString *)cid;
- (BOOL)deleteMessage:(NSString *)mid;
- (NSArray<CHMessageModel *> *)messageWithCID:(nullable NSString *)cid from:(NSString *)from to:(NSString *)to count:(NSUInteger)count;
- (nullable CHMessageModel *)messageWithMID:(nullable NSString *)mid;
- (BOOL)upsertMessageData:(NSData *)data ks:(id<CHKeyStorage>)ks uid:(NSString *)uid mid:(NSString *)mid cid:(NSString * _Nullable * _Nullable)cid;


@end

NS_ASSUME_NONNULL_END
