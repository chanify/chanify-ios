//
//  CHLinkMetaManager.h
//  Chanify
//
//  Created by WizJin on 2021/4/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CHLinkMetaItem <NSObject>

- (void)linkMetaUpdated:(nullable NSDictionary *)item;

@end

@interface CHLinkMetaManager : NSObject

@property (nonatomic, nullable, strong) NSString *uid;

+ (instancetype)linkManagerWithURL:(NSURL *)fileBaseDir;
- (void)loadMetaFromURL:(nullable NSURL *)url toItem:(id<CHLinkMetaItem>)item;
- (void)close;


@end

NS_ASSUME_NONNULL_END
