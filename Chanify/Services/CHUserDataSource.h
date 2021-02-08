//
//  CHUserDataSource.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CHChannelModel;
@class CHMessageModel;

@interface CHUserDataSource : NSObject

@property (nonatomic, readonly, strong) NSURL *dsURL;
@property (nonatomic, nullable, strong) NSData *srvkey;

+ (instancetype)dataSourceWithURL:(NSURL *)url;
- (void)close;
- (NSArray<CHChannelModel *> *)loadChannels;
- (nullable CHChannelModel *)channelWithCID:(nullable NSString *)cid;
- (NSArray<CHMessageModel *> *)messageWithCID:(nullable NSString *)cid from:(uint64_t)from to:(uint64_t)to count:(NSUInteger)count;
- (nullable CHMessageModel *)messageWithMID:(uint64_t)mid;
- (BOOL)upsertMessageData:(NSData *)data mid:(uint64_t)mid;


@end

NS_ASSUME_NONNULL_END
