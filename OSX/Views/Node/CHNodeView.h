//
//  CHNodeView.h
//  OSX
//
//  Created by WizJin on 2021/9/6.
//

#import "CHPageView.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHNodeView : CHPageView

@property (nonatomic, readonly, strong) NSString *nid;

- (instancetype)initWithNID:(NSString *)nid;


@end

NS_ASSUME_NONNULL_END
