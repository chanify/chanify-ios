//
//  IntentHandler.m
//  WidgetIntents
//
//  Created by WizJin on 2021/6/16.
//

#import "IntentHandler.h"
#import "ShortcutsConfigurationIntent.h"

@interface IntentHandler () <ShortcutsConfigurationIntentHandling>

@end

@implementation IntentHandler

- (id)handlerForIntent:(INIntent *)intent {
    // This is the default implementation.  If you want different objects to handle different intents,
    // you can override this and return the handler you want for that particular intent.
    
    return self;
}

#pragma mark - ShortcutsConfigurationIntentHandling
- (void)provideEntriesOptionsCollectionForShortcutsConfiguration:(ShortcutsConfigurationIntent *)intent withCompletion:(void (^)(INObjectCollection<EntryType *> * _Nullable entriesOptionsCollection, NSError * _Nullable error))completion {
    if (completion) {
        NSMutableArray<EntryType *> *items = [NSMutableArray new];
        [items addObject:[self entryWithIdentifier:@"action.scan" name:@"Scan"]];
        [items addObject:[self entryWithIdentifier:@"channel.sys.none" name:@"Uncategorized"]];
        [items addObject:[self entryWithIdentifier:@"channel.sys.device" name:@"Devices"]];
        completion([[INObjectCollection alloc] initWithItems:items], nil);
    }
}

- (nullable NSArray<EntryType *> *)defaultEntriesForShortcutsConfiguration:(ShortcutsConfigurationIntent *)intent {
    return  @[[self entryWithIdentifier:@"action.scan" name:@"Scan"]];
}

#pragma mark - Private Methods
- (EntryType *)entryWithIdentifier:(NSString *)identifier name:(NSString *)name {
    return [[EntryType alloc] initWithIdentifier:identifier displayString:name];
}


@end
