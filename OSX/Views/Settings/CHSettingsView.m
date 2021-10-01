//
//  CHSettingsView.m
//  OSX
//
//  Created by WizJin on 2021/10/1.
//

#import "CHSettingsView.h"
#import "CHWebFileManager.h"
#import "CHWebImageManager.h"
#import "CHWebAudioManager.h"
#import "CHWebLinkManager.h"
#import "CHFormView.h"
#import "CHDevice.h"
#import "CHRouter.h"
#import "CHLogic.h"

@interface CHSettingsView () <CHWebCacheManagerDelegate>

@property (nonatomic, readonly, strong) CHFormView *formView;

@end

@implementation CHSettingsView

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        CHFormView *formView = [[CHFormView alloc] initWithFrame:frameRect];
        [self initializeForm:formView];
        [self addSubview:(_formView = formView)];
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    CHLogic *logic = CHLogic.shared;
    [logic.webFileManager addDelegate:self];
    [logic.webImageManager addDelegate:self];
    [logic.webAudioManager addDelegate:self];
    [logic.webLinkManager addDelegate:self];
    [self webCacheAllocatedFileSizeChanged:logic.webFileManager];
    [self webCacheAllocatedFileSizeChanged:logic.webImageManager];
    [self webCacheAllocatedFileSizeChanged:logic.webAudioManager];
    [self webCacheAllocatedFileSizeChanged:logic.webLinkManager];
}

- (void)viewDidDisappear:(BOOL)animated {
    CHLogic *logic = CHLogic.shared;
    [logic.webFileManager removeDelegate:self];
    [logic.webImageManager removeDelegate:self];
    [logic.webAudioManager removeDelegate:self];
    [logic.webLinkManager removeDelegate:self];
    [super viewDidDisappear:animated];
}

- (void)layout {
    [super layout];
    self.formView.frame = self.bounds;
}

- (void)reloadData {
    [self.formView reloadData];
}

- (void)setRightBarButtonItem:(CHBarButtonItem *)rightBarButtonItem {
    self.formView.rightBarButtonItem = rightBarButtonItem;
}

- (CHBarButtonItem *)rightBarButtonItem {
    return self.formView.rightBarButtonItem;
}

#pragma mark - CHWebCacheManagerDelegate
- (void)webCacheAllocatedFileSizeChanged:(CHWebCacheManager *)manager {
    CHLogic *logic = CHLogic.shared;
    if (manager == logic.webImageManager) {
        CHFormValueItem *item = (CHFormValueItem *)[self.formView.form formItemWithName:@"images"];
        NSUInteger size = logic.webImageManager.allocatedFileSize;
        if ([item.value unsignedIntegerValue] != size) {
            item.value = @(size);
            [self.formView reloadItem:item];
        }
    } else if (manager == logic.webAudioManager) {
        CHFormValueItem *item = (CHFormValueItem *)[self.formView.form formItemWithName:@"audios"];
        NSUInteger size = logic.webAudioManager.allocatedFileSize;
        if ([item.value unsignedIntegerValue] != size) {
            item.value = @(size);
            [self.formView reloadItem:item];
        }
    } else if (manager == logic.webFileManager) {
        CHFormValueItem *item = (CHFormValueItem *)[self.formView.form formItemWithName:@"files"];
        NSUInteger size = logic.webFileManager.allocatedFileSize;
        if ([item.value unsignedIntegerValue] != size) {
            item.value = @(size);
            [self.formView reloadItem:item];
        }
    } else if (manager == logic.webLinkManager) {
        CHFormValueItem *item = (CHFormValueItem *)[self.formView.form formItemWithName:@"links"];
        NSUInteger size = logic.webLinkManager.allocatedFileSize;
        if ([item.value unsignedIntegerValue] != size) {
            item.value = @(size);
            [self.formView reloadItem:item];
        }
    }
}

#pragma mark - Private Methods
- (void)initializeForm:(CHFormView *)formView {
    CHFormItem *item;
    CHFormSection *section;
    CHForm *form = [CHForm formWithTitle:@"Settings".localized];
    
    // SECURITY
    [form addFormSection:(section = [CHFormSection sectionWithTitle:@"SECURITY".localized])];
    item = [CHFormValueItem itemWithName:@"blocklist" title:@"Token blocklist".localized];
    item.action = ^(CHFormItem *itm) {
        [CHRouter.shared routeTo:@"/page/blocklist" withParams:@{ @"show": @"detail" }];
    };
    [section addFormItem:item];
    
    // DATA
    [form addFormSection:(section = [CHFormSection sectionWithTitle:@"DATA".localized])];
    item = [CHFormValueItem itemWithName:@"images" title:@"Images".localized value:@(0)];
    item.action = ^(CHFormItem *itm) {
        [CHRouter.shared routeTo:@"/page/images" withParams:@{ @"show": @"detail" }];
    };
    [(CHFormValueItem *)item setFormatter:^(CHFormValueItem *item, NSNumber *value) {
        return [value formatFileSize];
    }];
    [section addFormItem:item];
    item = [CHFormValueItem itemWithName:@"audios" title:@"Audios".localized value:@(0)];
    item.action = ^(CHFormItem *itm) {
        [CHRouter.shared routeTo:@"/page/audios" withParams:@{ @"show": @"detail" }];
    };
    [(CHFormValueItem *)item setFormatter:^(CHFormValueItem *item, NSNumber *value) {
        return [value formatFileSize];
    }];
    [section addFormItem:item];
    item = [CHFormValueItem itemWithName:@"files" title:@"Files".localized value:@(0)];
    item.action = ^(CHFormItem *itm) {
        [CHRouter.shared routeTo:@"/page/files" withParams:@{ @"show": @"detail" }];
    };
    [(CHFormValueItem *)item setFormatter:^(CHFormValueItem *item, NSNumber *value) {
        return [value formatFileSize];
    }];
    [section addFormItem:item];
    item = [CHFormValueItem itemWithName:@"links" title:@"Links".localized value:@(0)];
    item.action = ^(CHFormItem *itm) {
        [CHRouter.shared routeTo:@"/page/links" withParams:@{ @"show": @"detail" }];
    };
    [(CHFormValueItem *)item setFormatter:^(CHFormValueItem *item, NSNumber *value) {
        return [value formatFileSize];
    }];
    [section addFormItem:item];

    // HELP
    [form addFormSection:(section = [CHFormSection sectionWithTitle:@"HELP".localized])];
    item = [CHFormValueItem itemWithName:@"quick" title:@"Quick Start".localized];
    item.action = ^(CHFormItem *itm) {
        [CHRouter.shared routeTo:@kQuickStartURL withParams:@{ @"title": @"Quick Start".localized, @"show": @"detail" }];
    };
    [section addFormItem:item];
    
    // ABOUT
    [form addFormSection:(section = [CHFormSection sectionWithTitle:@"ABOUT".localized])];
    item = [CHFormValueItem itemWithName:@"version" title:@"Version".localized value:CHDevice.shared.version];
    [section addFormItem:item];
    item = [CHFormValueItem itemWithName:@"privacy" title:@"Privacy Policy".localized];
    item.action = ^(CHFormItem *itm) {
        [CHRouter.shared routeTo:@"/page/privacy" withParams:@{ @"show": @"detail" }];
    };
    [section addFormItem:item];
    item = [CHFormValueItem itemWithName:@"acknowledgements" title:@"Acknowledgements".localized];
    item.action = ^(CHFormItem *itm) {
        [CHRouter.shared routeTo:@"/page/acknowledgements" withParams:@{ @"show": @"detail" }];
    };
    [section addFormItem:item];
    item = [CHFormValueItem itemWithName:@"contact-us" title:@"Contact Us".localized];
    item.hidden = [NSPredicate predicateWithObject:CHRouter.shared attribute:@"canSendMail" expected:@NO];
    item.action = ^(CHFormItem *itm) {
        [CHRouter.shared routeTo:@"/action/sendemail" withParams:@{ @"email": @kCHContactEmail, @"show": @"detail" }];
    };
    [section addFormItem:item];

    // LOGOUT
    [form addFormSection:(section = [CHFormSection section])];
    item = [CHFormButtonItem itemWithName:@"logout" title:@"Logout".localized action:^(CHFormItem *itm) {
        [CHRouter.shared routeTo:@"/action/logout"];
    }];
    [section addFormItem:item];

    formView.form = form;
}


@end
