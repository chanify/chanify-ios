//
//  CHLogger.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#ifndef __CHLOGGER_H__
#define __CHLOGGER_H__

#ifdef __cplusplus
extern "C" {
#endif

#ifdef DEBUG
    void CHLoggerOutput(char lvl, const char *format, ...);
#else
#   define CHLoggerOutput(...)  ((void *)0)
#endif

#define CHLogE(...)             CHLoggerOutput('E', ##__VA_ARGS__)
#define CHLogI(...)             CHLoggerOutput('I', ##__VA_ARGS__)
#define CHLogW(...)             CHLoggerOutput('W', ##__VA_ARGS__)
#define CHLogD(...)             CHLoggerOutput('D', ##__VA_ARGS__)
#define CHLogT(...)             CHLoggerOutput('T', ##__VA_ARGS__)


#ifdef __cplusplus
}
#endif

#endif /* __CHLOGGER_H__ */
