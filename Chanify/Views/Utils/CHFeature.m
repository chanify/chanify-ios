//
//  CHFeature.m
//  Chanify
//
//  Created by WizJin on 2021/9/24.
//

#import "CHFeature.h"

@implementation CHFeature

+ (CHImage *)featureIconWithName:(NSString *)name {
    static NSDictionary<NSString *, NSString *> *iconTable;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        iconTable = @{
            @"msg.text": @"doc.plaintext",
            @"msg.link": @"link",
            @"msg.action": @"arrow.left.arrow.right.circle",
            @"msg.image": @"photo",
            @"msg.video": @"video",
            @"msg.audio": @"waveform",
            @"msg.file": @"doc.richtext",
            @"msg.timeline": @"waveform.path.ecg",
            @"store.device": @"externaldrive.badge.person.crop",
            @"platform.watchos": @"applewatch",
            @"register.limit": @"lock.shield",
        };
    });
    NSString *image = [iconTable objectForKey:name];
    if (image.length > 0) {
        return [CHImage systemImageNamed:image];
    }
    return nil;
}


@end
