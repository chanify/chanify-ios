//
//  CHScriptViewController.m
//  iOS
//
//  Created by WizJin on 2022/4/23.
//

#import "CHScriptViewController.h"
#import <Masonry/Masonry.h>
#import "CHUserDataSource.h"
#import "CHScriptModel.h"
#import "CHRouter.h"
#import "CHLogic.h"
#import "CHTheme.h"

@interface CHScriptViewController () <UITextViewDelegate>

@property (nonatomic, nullable, strong) CHScriptModel *model;
@property (nonatomic, nullable, strong) NSString *scriptName;
@property (nonatomic, nullable, strong) NSString *scriptContent;
@property (nonatomic, readonly, strong) UITextView *contentView;

@end

@implementation CHScriptViewController

- (instancetype)initWithParameters:(NSDictionary *)params {
    if (self = [super init]) {
        _model = [CHLogic.shared.userDataSource scriptWithName:[params valueForKey:@"name"]];
    }
    return self;
}

- (instancetype)initWithName:(NSString *)name script:(nullable NSString *)script {
    if (self = [super init]) {
        _model = nil;
        _scriptName = name ?: @"";
        _scriptContent = script ?: @"";
    }
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    if (self.delegate != nil) {
        [self.delegate scriptViewController:self script:self.contentView.text];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CHTheme *theme = CHTheme.shared;
    
    UITextView *contentView = [UITextView new];
    [self.view addSubview:(_contentView = contentView)];
    [contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.left.right.bottom.equalTo(self.view);
    }];
    contentView.alwaysBounceVertical = YES;
    contentView.font = theme.textFont;
    contentView.textColor = theme.labelColor;
    contentView.backgroundColor = theme.backgroundColor;
    contentView.keyboardType = UIKeyboardTypeAlphabet;
    contentView.delegate = self;

    if (self.model == nil) {
        self.title = self.scriptName;
        contentView.text = self.scriptContent;
    } else {
        self.title = self.model.name;
        contentView.text = [CHLogic.shared.userDataSource scriptContentWithName:self.model.name];
        
        CHBarButtonItem *rightBarButtonItem = [CHBarButtonItem itemDoneWithTarget:self action:@selector(actionDone:)];
        self.navigationItem.rightBarButtonItem = rightBarButtonItem;
    }

    if (contentView.text.length <= 0) {
        @weakify(self);
        dispatch_main_after(kCHLoadingDuration, ^{
            @strongify(self);
            [self.contentView becomeFirstResponder];
        });
    }
    
    if (self.title.length <= 0) {
        self.title = @"Script".localized;
    }
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardDidChanged:) name:UIKeyboardDidChangeFrameNotification object:nil];
}

#pragma mark - UITextViewDelegate
- (void)textViewDidChange:(UITextView *)textView {
    
}

#pragma mark - Action Methods
- (void)actionDone:(id)sender {
    [self.contentView resignFirstResponder];
    if (self.model != nil) {
        if ([CHLogic.shared updateScript:self.model.name content:self.contentView.text]) {
            [self closeAnimated:YES completion:nil];
        } else {
            [CHRouter.shared makeToast:@"Save script failed".localized];
        }
    }
}

- (void)keyboardDidChanged:(NSNotification *)notification {
    CGRect rect = [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGPoint pt = [self.view convertPoint:CGPointMake(0, rect.origin.y) fromView:nil];
    
    [self.contentView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view).offset(MIN(pt.y - self.view.bounds.size.height, 0));
    }];
}


@end
