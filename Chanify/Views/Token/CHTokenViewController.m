//
//  CHTokenViewController.m
//  iOS
//
//  Created by WizJin on 2021/5/17.
//

#import "CHTokenViewController.h"
#import "CHUserDataSource.h"
#import "CHChannelModel.h"
#import "CHNodeModel.h"
#import "CHRouter.h"
#import "CHToken.h"
#import "CHLogic.h"
#import "CHUserModel.h"

// In-memory drafts preserve failed edits when the detail page is reopened.
static NSMutableDictionary<NSString *, NSString *> *tokenNameDrafts;
static NSString *const tokenNamesChanged = @"CHServerTokenNamesChanged";

@interface CHTokenViewController ()

@property (nonatomic, readonly, strong) CHChannelModel *model;
@property (nonatomic, readonly, strong) CHNodeModel *node;
@property (nonatomic, readonly, strong) CHFormSection *tokenSection;
@property (nonatomic, strong) NSDate *selectedExpiration;
@property (nonatomic, strong) CHUserModel *owner;
@property (nonatomic, assign) BOOL generating;
@property (nonatomic, assign) BOOL busy;
@property (nonatomic, assign) BOOL loadedRecords;
@property (nonatomic, assign) BOOL renamePending;
@property (nonatomic, copy) NSString *detailID;
@property (nonatomic, copy) NSString *pendingToken;
@property (nonatomic, copy) NSArray<NSDictionary *> *records;
@property (nonatomic, copy) NSString *loadError;
#if !TARGET_OS_OSX
@property (nonatomic, strong) UIRefreshControl *tokenRefreshControl;
#endif


@end

@implementation CHTokenViewController

- (instancetype)initWithParameters:(NSDictionary *)params {
    if (self = [super init]) {
        NSString *nid = [params valueForKey:@"nid"];
        if (nid.length > 0) {
            _node = [CHLogic.shared.userDataSource nodeWithNID:nid];
            if (!_node.isSupportServerToken) return nil;
            _owner = CHLogic.shared.me;
            _generating = [[params valueForKey:@"generate"] boolValue];
            _detailID = [params valueForKey:@"token-id"];
            _records = @[];
        } else {
            _model = [CHLogic.shared.userDataSource channelWithCID:[params valueForKey:@"cid"]];
            if (_model == nil) return nil;
        }
        [self initializeForm];
        [self updateTokenNavigation];
    }
    return self;
}

- (BOOL)isEqualWithParameters:(NSDictionary *)params {
    if (self.node != nil) {
        return [self.node.nid isEqualToString:[params valueForKey:@"nid"]]
            && self.generating == [[params valueForKey:@"generate"] boolValue]
            && ((self.detailID == nil && [params valueForKey:@"token-id"] == nil)
                || [self.detailID isEqualToString:[params valueForKey:@"token-id"]]);
    }
    return [params valueForKey:@"nid"] == nil && [self.model.cid isEqualToString:[params valueForKey:@"cid"]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self updateTokenNavigation];
    if (self.node != nil && !self.generating && self.detailID == nil) {
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(serverTokenNamesChanged:) name:tokenNamesChanged object:nil];
    }
#if !TARGET_OS_OSX
    if (self.node != nil && !self.generating && self.detailID == nil) {
        for (UIView *view in self.view.subviews) {
            if ([view isKindOfClass:UITableView.class]) {
                self.tokenRefreshControl = [UIRefreshControl new];
                [self.tokenRefreshControl addTarget:self action:@selector(refreshServerTokens:) forControlEvents:UIControlEventValueChanged];
                ((UITableView *)view).refreshControl = self.tokenRefreshControl;
                break;
            }
        }
    }
#endif
}

- (void)endTokenRefreshing {
#if !TARGET_OS_OSX
    [self.tokenRefreshControl endRefreshing];
#endif
}

#if !TARGET_OS_OSX
- (void)refreshServerTokens:(UIRefreshControl *)sender {
    [self loadServerTokens];
}
#endif

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.node != nil && !self.generating) [self loadServerTokens];
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.node != nil && !self.generating && self.detailID != nil) {
#if !TARGET_OS_OSX
        [self.view endEditing:YES];
#endif
        [self renameServerToken];
    }
}

- (NSString *)nameDraftKey {
    return [NSString stringWithFormat:@"%@/%@/%@", self.owner.uid, self.node.nid, self.detailID];
}

- (void)serverTokenNamesChanged:(NSNotification *)notification {
    if ([notification.userInfo[@"user"] isEqual:self.owner.uid] && [notification.userInfo[@"node"] isEqual:self.node.nid]) [self loadServerTokens];
}

- (void)updateTokenNavigation {
    if (self.node != nil) {
        self.rightBarButtonItem = (!self.generating && self.detailID == nil)
            ? [CHBarButtonItem itemWithIcon:@"plus" target:self action:@selector(addServerToken:)] : nil;
    }
}

- (void)addServerToken:(id)sender {
    [CHRouter.shared routeTo:@"/page/token" withParams:@{ @"nid": self.node.nid, @"generate": @YES }];
}

#pragma mark - Private Methods
- (void)initializeForm{
    if (self.node != nil && !self.generating) {
        [self initializeServerTokenForm];
        return;
    }
    @weakify(self);

    CHFormSection *section;
    CHForm *form = [CHForm formWithTitle:@"Generate Token".localized];
    
    [form addFormSection:(section = [CHFormSection section])];
    if (self.node != nil) {
        [section addFormItem:[CHFormValueItem itemWithName:@"node" title:@"Node".localized value:self.node.name]];
        section.note = @"This token can send messages to different channels on this server. If no channel is specified, messages go to Uncategorized.".localized;
    } else {
        [section addFormItem:[CHFormValueItem itemWithName:@"channel" title:@"Channel".localized value:self.model.title]];
    }
    
    if (self.node != nil) {
        CHFormInputItem *name = [CHFormInputItem itemWithName:@"token-name" title:@"Name".localized value:@""];
        name.required = YES;
        [section addFormItem:name];
    }
    NSTimeInterval day = 60*60*24;
    NSDate *select = [NSDate dateWithTimeIntervalSinceNow:day*90];
    CHFormDateItem *dateItem = [CHFormDateItem itemWithName:@"expire" title:@"Expire".localized value:select];
    [section addFormItem:dateItem];
    dateItem.minimumDate = [NSDate dateWithTimeIntervalSinceNow:day];
    dateItem.maximumDate = [NSDate dateWithTimeIntervalSinceNow:day*365*5];
    dateItem.onChanged = ^(CHFormDateItem *item, NSDate *oldValue, NSDate *newValue) {
        if (![oldValue isEqualToDate:newValue]) {
            @strongify(self);
            [self updateDate:newValue];
        }
    };
    if (self.node != nil) {
        [section addFormItem:[CHFormButtonItem itemWithName:@"generate-token" title:@"Generate Token".localized action:^(CHFormItem *item) {
            @strongify(self);
            [self generateServerToken];
        }]];
    }
    [form addFormSection:(_tokenSection = [CHFormSection sectionWithTitle:@"Token".localized])];
    if (self.node != nil) {
        self.tokenSection.note = @"Choose an expiry date, then tap Generate Token.".localized;
    }
    for (CHNodeModel *model in (self.node != nil ? @[self.node] : [CHLogic.shared.userDataSource loadNodes])) {
        CHFormCodeItem *item = [CHFormCodeItem itemWithName:[@"token." stringByAppendingString:model.nid] title:model.name value:@""];
        [self.tokenSection addFormItem:item];
        if (self.node == nil) item.copiedName = @"Token".localized;
    }
    self.form = form;
    
    [self updateDate:select];
}

- (void)updateDate:(NSDate *)date {
    if (self.node != nil) {
        if (self.pendingToken != nil) {
            CHFormDateItem *item = (CHFormDateItem *)[self.form formItemWithName:@"expire"];
            item.value = self.selectedExpiration;
            [self reloadSection:item.section];
            return;
        }
        self.selectedExpiration = date;
        return;
    }
    CHToken *tk = [CHToken tokenWithDate:date];
    tk.channel = [NSData dataFromBase64:self.model.cid];
    for (CHNodeModel *model in [CHLogic.shared.userDataSource loadNodes]) {
        CHFormCodeItem *item = [self.tokenSection itemWithName:[@"token." stringByAppendingString:model.nid]];
        if (item != nil) {
            tk.node = model;
            item.value = [tk formatString:model.nid direct:model.isStoreDevice];
        }
    }
    self.tokenSection.note = [NSString stringWithFormat:@"Expires at %@".localized, tk.expired.fullDayFormat];
    [self reloadSection:self.tokenSection];
}


- (void)requestTokenAction:(NSString *)action values:(NSDictionary *)values completion:(void (^)(NSArray<NSDictionary *> *records))completion {
    if (self.busy || ![CHLogic.shared.me.uid isEqualToString:self.owner.uid]) {
        [self endTokenRefreshing];
        return;
    }
    CHNodeModel *node = [CHLogic.shared.userDataSource nodeWithNID:self.node.nid];
    if (!node.isSupportServerToken) {
        [self endTokenRefreshing];
        [CHRouter.shared makeToast:@"Server token unavailable. Refresh or reconnect this node.".localized];
        return;
    }
    self.busy = YES;
    NSMutableDictionary *parameters = [values mutableCopy];
    parameters[@"user"] = self.owner.uid;
    parameters[@"action"] = action;
    @weakify(self);
    [CHLogic.shared sendToEndpoint:node.apiURL cmd:@"server-tokens" device:NO seckey:node.requestChiper user:self.owner parameters:parameters completion:^(NSURLResponse *response, NSDictionary *result, NSError *error) {
        @strongify(self);
        if (self == nil) return;
        self.busy = NO;
        [self endTokenRefreshing];
        if (![CHLogic.shared.me.uid isEqualToString:self.owner.uid]) return;
        id records = result[@"tokens"];
        BOOL valid = error == nil && [(NSHTTPURLResponse *)response statusCode] == 200 && [records isKindOfClass:NSArray.class];
        if (valid) for (id record in records) {
            if (![record isKindOfClass:NSDictionary.class] || ![record[@"id"] isKindOfClass:NSString.class]
                || ![record[@"name"] isKindOfClass:NSString.class] || ![record[@"expires"] isKindOfClass:NSNumber.class]
                || ![record[@"encrypted_token"] isKindOfClass:NSString.class]) { valid = NO; break; }
        }
        if (!valid) {
            self.loadError = @"Could not update tokens. Please try again.".localized;
            [CHRouter.shared makeToast:self.loadError];
            if (!self.generating && ![action isEqualToString:@"rename"]) [self initializeServerTokenForm];
            return;
        }
        self.loadError = nil;
        self.records = records;
        self.loadedRecords = YES;
        if (completion != nil) completion(records);
        if (self.renamePending) {
            self.renamePending = NO;
            [self renameServerToken];
        }
    }];
}

- (void)loadServerTokens {
    @weakify(self);
    [self requestTokenAction:@"list" values:@{} completion:^(NSArray *records) {
        @strongify(self);
        [self initializeServerTokenForm];
    }];
}

- (void)generateServerToken {
    if (self.busy || ![CHLogic.shared.me.uid isEqualToString:self.owner.uid]) return;
    NSString *name = [[self.form.formValues valueForKey:@"token-name"] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (name.length == 0 || [name lengthOfBytesUsingEncoding:NSUTF8StringEncoding] > 128) {
        [CHRouter.shared makeToast:@"Enter a token name (up to 128 UTF-8 bytes).".localized];
        return;
    }
    CHNodeModel *node = [CHLogic.shared.userDataSource nodeWithNID:self.node.nid];
    if (self.pendingToken == nil) self.pendingToken = [CHToken serverTokenForNode:node date:self.selectedExpiration];
    if (self.pendingToken == nil) {
        [CHRouter.shared makeToast:@"Server token unavailable. Refresh or reconnect this node.".localized];
        return;
    }
    CHFormDateItem *expiry = (CHFormDateItem *)[self.form formItemWithName:@"expire"];
    expiry.minimumDate = self.selectedExpiration;
    expiry.maximumDate = self.selectedExpiration;
    self.tokenSection.note = @"Generation has started. Retry with the same expiry date if the request fails.".localized;
    [self reloadSection:expiry.section];
    [self reloadSection:self.tokenSection];
    NSString *identifier = [CHToken tokenWithString:self.pendingToken].identifier;
    @weakify(self);
    [self requestTokenAction:@"create" values:@{ @"name": name, @"token": self.pendingToken } completion:^(NSArray *records) {
        @strongify(self);
        self.detailID = identifier;
        self.generating = NO;
        self.pendingToken = nil;
        [self initializeServerTokenForm];
    }];
}

- (void)initializeServerTokenForm {
    [self updateTokenNavigation];
    CHForm *form = [CHForm formWithTitle:(self.detailID == nil ? @"Sending Tokens" : @"Token Detail").localized];
    CHFormSection *section = [CHFormSection section];
    [form addFormSection:section];
    @weakify(self);
    if (self.detailID == nil) {
        section.note = self.loadError ?: @"Create tokens with the add button. If no channel is specified, messages go to Uncategorized.".localized;
        if (self.records.count == 0) {
            NSString *emptyTitle = self.loadError ?: (self.loadedRecords ? @"No sending tokens".localized : @"Loading tokens…".localized);
            [section addFormItem:[CHFormValueItem itemWithName:@"empty" title:emptyTitle]];
        }
        for (NSDictionary *record in self.records) {
            NSDate *expiry = [NSDate dateWithTimeIntervalSince1970:[record[@"expires"] doubleValue]];
            NSString *value = [NSString stringWithFormat:@"%@%@", expiry.fullDayFormat, expiry.timeIntervalSinceNow <= 0 ? [@" · " stringByAppendingString:@"Expired".localized] : @""];
            CHFormValueItem *item = [CHFormValueItem itemWithName:record[@"id"] title:record[@"name"] value:value];
            item.action = ^(CHFormItem *item) {
                @strongify(self);
                [CHRouter.shared routeTo:@"/page/token" withParams:@{ @"nid": self.node.nid, @"token-id": record[@"id"] }];
            };
            [section addFormItem:item];
        }
    } else {
        NSDictionary *record = nil;
        for (NSDictionary *candidate in self.records) if ([candidate[@"id"] isEqualToString:self.detailID]) { record = candidate; break; }
        if (record != nil) {
            CHFormInputItem *name = [CHFormInputItem itemWithName:@"token-name" title:@"Name".localized value:tokenNameDrafts[self.nameDraftKey] ?: record[@"name"]];
            name.required = YES;
            name.onChanged = ^(CHFormItem *item, id oldValue, id newValue) {
                @strongify(self);
                if (self == nil) return;
                if (tokenNameDrafts == nil) tokenNameDrafts = [NSMutableDictionary new];
                tokenNameDrafts[self.nameDraftKey] = newValue;
            };
            name.onEditingEnded = ^(CHFormItem *item) {
                @strongify(self);
                [self renameServerToken];
            };
            [section addFormItem:name];
            NSDate *expiry = [NSDate dateWithTimeIntervalSince1970:[record[@"expires"] doubleValue]];
            [section addFormItem:[CHFormValueItem itemWithName:@"expires" title:@"Expire".localized value:expiry.fullDayFormat]];
            NSData *encrypted = [NSData dataFromBase64:record[@"encrypted_token"]];
            NSData *plaintext = [self.owner.key decode:encrypted];
            NSString *raw = plaintext.length > 0 ? [[NSString alloc] initWithData:plaintext encoding:NSUTF8StringEncoding] : nil;
            if ([raw hasPrefix:@"cst1:"] && [[CHToken tokenWithString:raw].identifier isEqualToString:self.detailID]) {
                CHFormCodeItem *code = [CHFormCodeItem itemWithName:@"raw-token" title:@"Token".localized value:raw];
                code.copiedName = @"Token".localized;
                [section addFormItem:code];
            }
            [section addFormItem:[CHFormButtonItem itemWithName:@"revoke" title:@"Delete Token".localized action:^(CHFormItem *item) {
                @strongify(self);
                [self deleteServerToken];
            }]];
        } else {
            [section addFormItem:[CHFormValueItem itemWithName:@"unavailable" title:@"Token unavailable".localized]];
        }
    }
#if TARGET_OS_OSX
    [section addFormItem:[CHFormButtonItem itemWithName:@"refresh" title:@"Refresh".localized action:^(CHFormItem *item) {
        @strongify(self);
        [self loadServerTokens];
    }]];
#endif
    self.form = form;
}

- (void)renameServerToken {
    if (self.detailID == nil || ![CHLogic.shared.me.uid isEqualToString:self.owner.uid]) return;
    CHFormValueItem *item = (CHFormValueItem *)[self.form formItemWithName:@"token-name"];
    if (item == nil) return;
    NSString *name = [(NSString *)item.value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSString *savedName = nil;
    for (NSDictionary *record in self.records) if ([record[@"id"] isEqual:self.detailID]) savedName = record[@"name"];
    if (savedName == nil) return;
    if (self.busy) {
        if (tokenNameDrafts == nil) tokenNameDrafts = [NSMutableDictionary new];
        tokenNameDrafts[self.nameDraftKey] = item.value ?: @"";
        self.renamePending = YES;
        return;
    }
    if ([name isEqualToString:savedName]) {
        [tokenNameDrafts removeObjectForKey:self.nameDraftKey];
        return;
    }
    if (tokenNameDrafts == nil) tokenNameDrafts = [NSMutableDictionary new];
    tokenNameDrafts[self.nameDraftKey] = item.value ?: @"";
    if (name.length == 0 || [name lengthOfBytesUsingEncoding:NSUTF8StringEncoding] > 128) {
        [CHRouter.shared makeToast:@"Enter a token name (up to 128 UTF-8 bytes).".localized];
        return;
    }
    // Retain this page until the save finishes, including when navigating back.
    [self requestTokenAction:@"rename" values:@{ @"id": self.detailID, @"name": name } completion:^(NSArray *records) {
        CHFormValueItem *current = (CHFormValueItem *)[self.form formItemWithName:@"token-name"];
        NSString *currentName = [(NSString *)current.value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if ([currentName isEqualToString:name]) {
            [tokenNameDrafts removeObjectForKey:self.nameDraftKey];
            current.value = name;
            [self reloadItem:current];
        }
        [NSNotificationCenter.defaultCenter postNotificationName:tokenNamesChanged object:nil userInfo:@{ @"user": self.owner.uid, @"node": self.node.nid }];
    }];
}

- (void)deleteServerToken {
    @weakify(self);
    [CHRouter.shared showAlertWithTitle:@"Delete this token? It will stop working immediately.".localized action:@"Delete Token".localized handler:^{
        @strongify(self);
        if (self.busy) {
            [CHRouter.shared makeToast:@"Please wait for the current operation, then try again.".localized];
            return;
        }
        [self requestTokenAction:@"revoke" values:@{ @"id": self.detailID } completion:^(NSArray *records) {
            @strongify(self);
            [tokenNameDrafts removeObjectForKey:self.nameDraftKey];
            self.detailID = nil;
            [self closeAnimated:YES completion:nil];
        }];
    }];
}

@end
