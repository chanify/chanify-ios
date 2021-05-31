//
//  CHRouter+OSX.h
//  OSX
//
//  Created by WizJin on 2021/5/31.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHRouter : NSObject

@property (nonatomic, readonly, strong) NSWindow *window;

+ (instancetype)shared;
- (void)launch;
- (void)close;
- (void)handleReopen:(id)sender;


@end

NS_ASSUME_NONNULL_END
