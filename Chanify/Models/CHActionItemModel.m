//
//  CHActionItemModel.m
//  Chanify
//
//  Created by WizJin on 2021/5/13.
//

#import "CHActionItemModel.h"

@implementation CHActionItemModel

+ (instancetype)actionItemWithName:(NSString *)name link:(nullable NSURL *)link {
    return [[self.class alloc] initWithName:name link:link];
}

+ (nullable instancetype)actionItemWithDictionary:(NSDictionary *)info {
    NSString *name = [info valueForKey:@"name"];
    NSString *link = [info valueForKey:@"link"] ?: @"";
    if (name.length > 0) {
        return [self.class actionItemWithName:name link:[NSURL URLWithString:link]];
    }
    return nil;
}

- (instancetype)initWithName:(NSString *)name link:(nullable NSURL *)link {
    if (self = [super init]) {
        _name = name ?: @"";
        _link = link;
    }
    return self;
}

- (NSDictionary *)dictionary {
    return @{
        @"name": self.name,
        @"link": self.link.absoluteString ?: @"",
    };
}


@end
