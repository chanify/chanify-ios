//
//  CHNodeView.h
//  OSX
//
//  Created by WizJin on 2021/9/6.
//

#import "CHFormView.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHNodeView : CHFormView

@property (nonatomic, readonly, strong) NSString *nid;

- (instancetype)initWithNID:(NSString *)nid;


@end

NS_ASSUME_NONNULL_END
