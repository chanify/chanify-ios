//
//  CHLogger.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHLogger.h"

#ifdef DEBUG

#import <CoreFoundation/CoreFoundation.h>
#import <stdio.h>
#import <stdarg.h>
#import <sys/time.h>

static inline int itoa(char *output, int i, int width) {
    for (int idx = width - 1; idx >= 0; idx--) {
        output[idx] = i%10 + '0';
        i /= 10;
    }
    return width;
}

void CHLoggerOutput(char lvl, const char *format, ...) {
    const uint32_t mask = CFSwapInt32HostToLittle(0x207C2000);

    char output[8*1024];
    char *p = output;

    struct tm now;
    struct timeval tv;
    gettimeofday(&tv, NULL);
    localtime_r(&tv.tv_sec, &now);
    p += itoa(p, 1900 + now.tm_year, 4); *p++ = '/';
    p += itoa(p, now.tm_mon,  2); *p++ = '/';
    p += itoa(p, now.tm_mday, 2); *p++ = ' ';
    p += itoa(p, now.tm_hour, 2); *p++ = ':';
    p += itoa(p, now.tm_min,  2); *p++ = ':';
    p += itoa(p, now.tm_sec,  2); *p++ = '.';
    p += itoa(p, tv.tv_usec,  6); *p++ = ' ';
    *(uint32_t *)p = mask | lvl;
    p += sizeof(uint32_t);
    va_list args;
    va_start(args, format);
    p += vsnprintf(p, sizeof(output) - (p - output), format, args);
    va_end (args);
    if (*(p-1) != '\n') *(p++) = '\n';
    fwrite(output, p - output, 1, stdout);
}


#endif
