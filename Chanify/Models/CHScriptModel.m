//
//  CHScriptModel.m
//  Chanify
//
//  Created by WizJin on 2022/4/1.
//

#import "CHScriptModel.h"

@implementation CHScriptModel

+ (instancetype)modelWithName:(NSString *)name type:(NSString *)type lastupdate:(NSDate *)lastupdate {
    return [[self.class alloc] initWithName:name type:type lastupdate:lastupdate];
}

- (instancetype)initWithName:(NSString *)name type:(NSString *)type lastupdate:(NSDate *)lastupdate {
    if (self = [super init]) {
        _name = name;
        _type = type;
        _lastupdate = lastupdate;
    }
    return self;
}

- (BOOL)isEqual:(CHScriptModel *)rhs {
    return ([self.name isEqualToString:rhs.name]
            && [self.type isEqualToString:rhs.type]
            && [self.lastupdate isEqual:rhs.lastupdate]);
}

- (NSUInteger)hash {
    return self.name.hash;
}


@end
