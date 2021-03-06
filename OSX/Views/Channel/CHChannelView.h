//
//  CHChannelView.h
//  OSX
//
//  Created by WizJin on 2021/6/1.
//

#import "CHUI.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHChannelView : NSView

@property (nonatomic, readonly, strong) NSString *cid;

- (instancetype)initWithCID:(NSString *)cid;


@end

NS_ASSUME_NONNULL_END
