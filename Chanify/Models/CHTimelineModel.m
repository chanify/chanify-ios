//
//  CHTimelineModel.m
//  Chanify
//
//  Created by WizJin on 2021/8/22.
//

#import "CHTimelineModel.h"
#import "CHTP.pbobjc.h"

@interface CHTimelineModel ()

@property (nonatomic, readonly, strong) CHTPTimeContent *content;
@property (nonatomic, nullable, strong) NSDictionary *valuesCache;

@end

@implementation CHTimelineModel

+ (nullable instancetype)timelineWithContent:(nullable CHTPTimeContent *)content {
    if (content != nil) {
        return [[self.class alloc] initWithContent:content];
    }
    return nil;
}

- (instancetype)initWithContent:(nullable CHTPTimeContent *)content {
    if (self = [super init]) {
        _content = content;
        _valuesCache = nil;
    }
    return self;
}

- (NSString *)code {
    return self.content.code;
}

- (NSDate *)timestamp {
    return [NSDate dateWithTimeIntervalSince1970:self.content.timestamp/1000.0];
}

- (NSDictionary *)values {
    if (self.valuesCache == nil) {
        NSMutableDictionary *items = [NSMutableDictionary dictionaryWithCapacity:self.content.timeItemsArray_Count];
        for (CHTPTimeItem *item in self.content.timeItemsArray) {
            switch (item.valueType) {
                default:
                    continue;
                case CHTPValueType_ValueTypeInteger:
                    [items setValue:@(item.integerValue) forKey:item.name];
                    break;
                case CHTPValueType_ValueTypeDouble:
                    [items setValue:@(item.doubleValue) forKey:item.name];
                    break;
            }
        }
        _valuesCache = items;
    }
    return self.valuesCache;
}

- (NSData *)data {
    return self.content.data;
}


@end
