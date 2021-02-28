//
//  CHNodeModel.m
//  Chanify
//
//  Created by WizJin on 2021/2/25.
//

#import "CHNodeModel.h"

@implementation CHNodeModel

+ (instancetype)modelWithNID:(nullable NSString *)nid name:(nullable NSString *)name url:(nullable NSString *)url {
    if (nid != nil) {
        return [[self.class alloc] initWithNID:nid name:name url:url];
    }
    return nil;
}

- (instancetype)initWithNID:(NSString *)nid name:(nullable NSString *)name url:(nullable NSString *)url {
    if (self = [super init]) {
        _nid = nid;
        _name = (name == nil ? @"" : name);
        _url = (url == nil ? @"" : url);
        if (nid.length <= 0) {
            if (name.length <= 0) _name = @"Chanify".localized;
            if (url.length <= 0) _url = [@"https://" stringByAppendingString:@kCHAPIHostname];
        }
    }
    return self;
}

- (BOOL)isEqual:(CHNodeModel *)rhs {
    return [self.nid isEqualToString:rhs.nid];
}

- (NSUInteger)hash {
    return self.nid.hash;
}


@end
