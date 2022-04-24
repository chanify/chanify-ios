//
//  CHJSConsole.h
//  Chanify
//
//  Created by WizJin on 2022/4/24.
//

#import <JavaScriptCore/JavaScriptCore.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CHJSIConsole<JSExport>

JSExportAs(log, - (void)doLog:(id)msg);
JSExportAs(info, - (void)doInfo:(id)msg);
JSExportAs(warn, - (void)doWarn:(id)msg);
JSExportAs(debug, - (void)doDebug:(id)msg);
JSExportAs(error, - (void)doError:(id)msg);
JSExportAs(assert, - (void)doAssert:(BOOL)flag);

@end

@interface CHJSConsole : NSObject<CHJSIConsole>

+ (instancetype)shared;


@end

NS_ASSUME_NONNULL_END
