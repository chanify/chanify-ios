//
//  CHJSBuffer.h
//  Chanify
//
//  Created by WizJin on 2022/4/24.
//

#import <JavaScriptCore/JavaScriptCore.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CHJSIBuffer<JSExport>

JSExportAs(byteLength, - (NSInteger)byteLength:(id)data);

@end

@interface CHJSBuffer : NSObject<CHJSIBuffer>

+ (instancetype)shared;


@end

NS_ASSUME_NONNULL_END
