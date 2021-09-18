//
//  CHListContentConfiguration.m
//  OSX
//
//  Created by WizJin on 2021/9/18.
//

#import "CHListContentConfiguration.h"

@implementation CHListContentConfiguration

+ (instancetype)valueCellConfiguration {
    return nil;
}

+ (instancetype)cellConfiguration {
    return nil;
}

- (__kindof NSView<CHContentView> *)makeContentView {
    return nil;
}

- (instancetype)updatedConfigurationForState:(id<CHConfigurationState>)state {
    return nil;
}


- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return nil;
}

@end
