//
//  JSValue+CHExt.m
//  Chanify
//
//  Created by WizJin on 2022/4/27.
//

#import "JSValue+CHExt.h"

@implementation JSValue (CHExt)

- (BOOL)isFunction {
    BOOL res = NO;
    if (self != nil) {
        JSContextRef context = self.context.JSGlobalContextRef;
        JSObjectRef obj = JSValueToObject(context, self.JSValueRef, NULL);
        res = JSObjectIsFunction(context, obj);
    }
    return res;
}



@end
