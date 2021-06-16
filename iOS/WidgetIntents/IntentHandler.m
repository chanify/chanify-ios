//
//  IntentHandler.m
//  WidgetIntents
//
//  Created by WizJin on 2021/6/16.
//

#import "IntentHandler.h"
#import "ShortcutsConfigurationIntent.h"
#import "NSString+CHLocalized.h"

@interface IntentHandler () <ShortcutsConfigurationIntentHandling>

@property (nonatomic, readonly, strong) NSArray<NSString *> *types;

@end

@implementation IntentHandler

- (instancetype)init {
    if (self = [super init]) {
        _types = @[@"action", @"channel", @"node"];
    }
    return self;
}

- (id)handlerForIntent:(INIntent *)intent {
    // This is the default implementation.  If you want different objects to handle different intents,
    // you can override this and return the handler you want for that particular intent.
    
    return self;
}

#pragma mark - ShortcutsConfigurationIntentHandling
- (void)provideEntriesOptionsCollectionForShortcutsConfiguration:(ShortcutsConfigurationIntent *)intent withCompletion:(void (^)(INObjectCollection<EntryType *> * _Nullable entriesOptionsCollection, NSError * _Nullable error))completion {
    if (completion) {
        NSMutableArray<EntryType *> *items = [NSMutableArray new];
        [items addObject:[self entryWithIdentifier:@"action.scan"]];
        [items addObject:[self entryWithIdentifier:@"channel.sys.none"]];
        [items addObject:[self entryWithIdentifier:@"channel.sys.device"]];
        completion([[INObjectCollection alloc] initWithItems:items], nil);
    }
}

- (nullable NSArray<EntryType *> *)defaultEntriesForShortcutsConfiguration:(ShortcutsConfigurationIntent *)intent {
    return  @[[self entryWithIdentifier:@"action.scan"]];
}

#pragma mark - Private Methods
- (EntryType *)entryWithIdentifier:(NSString *)identifier {
    NSString *title = @"";
    for (NSString *name in self.types) {
        NSInteger index = name.length;
        if ([identifier hasPrefix:name] && [identifier characterAtIndex:index] == '.') {
            title = [NSString stringWithFormat:@"%@: %@", name.localized, [identifier substringFromIndex:index + 1].localized];
            break;
        }
    }
    EntryType *entry = [[EntryType alloc] initWithIdentifier:identifier displayString:title];
    entry.icon = @"";
    entry.link = @"chanify:///action/scan";
    return entry;
}


@end
