//
//  CHUtils.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHUtils.h"
#import <objc/runtime.h>
#import <stdio.h>

dispatch_queue_t dispatch_queue_create_for(id obj, dispatch_queue_attr_t attr) {
    char uid[64];
    snprintf(uid, sizeof(uid), "%s.%lx", class_getName([obj class]), (unsigned long)[obj hash]);
    return dispatch_queue_create(uid, attr);
}
