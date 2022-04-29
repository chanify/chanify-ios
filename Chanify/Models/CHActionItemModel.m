//
//  CHActionItemModel.m
//  Chanify
//
//  Created by WizJin on 2021/5/13.
//

#import "CHActionItemModel.h"

@implementation CHActionItemModel

+ (instancetype)actionItemWithName:(NSString *)name link:(nullable NSURL *)link mid:(nullable NSString *)mid {
    return [[self.class alloc] initWithName:name link:link mid:mid];
}

+ (nullable instancetype)actionItemWithDictionary:(NSDictionary *)info {
    NSString *name = [info valueForKey:@"name"];
    NSString *link = [info valueForKey:@"link"] ?: @"";
    if (name.length > 0) {
        return [self.class actionItemWithName:name link:[NSURL URLWithString:link] mid:nil];
    }
    return nil;
}

- (instancetype)initWithName:(NSString *)name link:(nullable NSURL *)link mid:(nullable NSString *)mid {
    if (self = [super init]) {
        if (link != nil && mid != nil) {
            NSString *lnk = link.absoluteString;
            if ([lnk hasPrefix:@"chanify://action/run-script/"]) {
                if (link.query.length > 0) {
                    lnk = [lnk stringByAppendingFormat:@"&msgid=%@", mid];
                } else {
                    lnk = [lnk stringByAppendingFormat:@"?msgid=%@", mid];
                }
                link = [NSURL URLWithString:lnk];
            }
        }
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
