//
//  NSData+CHExt.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "NSData+CHExt.h"
#import <CommonCrypto/CommonDigest.h>

// Note: https://tools.ietf.org/rfc/rfc4648.txt

@implementation NSData (CHExt)

+ (instancetype)dataFromHex:(nullable NSString *)str {
    size_t len = str.length;
    if (len > 0) {
        NSMutableData *data = [NSMutableData dataWithLength:len/2];
        uint8_t *pout = (uint8_t *)data.mutableBytes;
        for (int i = 0; i < len/2; i++) {
            pout[i] = ((char2byte([str characterAtIndex:i*2]) << 4) | char2byte([str characterAtIndex:i*2+1]));
        }
        return data;
    }
    return NSData.data;
}

+ (instancetype)dataFromBase32:(nullable NSString *)str {
    size_t len = str.length;
    if (len > 0) {
        NSMutableData *data = [NSMutableData dataWithLength:(len*5 + 7)/8];
        size_t cnt = base32_decode((const uint8_t *)str.UTF8String, len, data.mutableBytes, data.length);
        if (cnt > 0) {
            data.length = cnt;
            return data;
        }
    }
    return NSData.data;
}

+ (instancetype)dataFromBase64:(nullable NSString *)str {
    size_t len = str.length;
    if (len > 0) {
        const uint8_t *ptr = (const uint8_t *)str.UTF8String;
        NSMutableData *data = [NSMutableData dataWithLength:base64_decode_len(ptr)];
        size_t cnt = base64_decode(ptr, len, data.mutableBytes, data.length);
        if (cnt > 0) {
            data.length = cnt;
            return data;
        }
    }
    return NSData.data;
}

+ (instancetype)dataFromNoCacheURL:(NSURL *)url {
    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfURL:url options:NSDataReadingUncached error:&error];
    if (error != nil) {
        data = nil;
        CHLogE("Load file failed: %s", error.description.cstr);
    }
    return data;
}

- (NSString *)hex {
    static const char *tbl = "0123456789ABCDEF";

    size_t len = self.length;
    if (len > 0) {
        const uint8_t *ptr = self.bytes;
        uint16_t *pout = malloc(sizeof(uint16_t)*len);
        if (pout != NULL) {
            for (int i = 0; i < len; i++) {
                uint8_t c = ptr[i];
#if BYTE_ORDER == BIG_ENDIAN
                pout[i] = (uint16_t)(tbl[c&0x0f]) | ((uint16_t)(tbl[(c>>4)&0x0f]) << 8);
#else
                pout[i] = ((uint16_t)(tbl[c&0x0f]) << 8) | (uint16_t)(tbl[(c>>4)&0x0f]);
#endif
            }
            return [[NSString alloc] initWithBytesNoCopy:pout length:(sizeof(uint16_t)*len) encoding:NSASCIIStringEncoding freeWhenDone:YES];
        }
    }
    return @"";
}

- (NSString *)base32 {
    NSMutableData *data = [NSMutableData dataWithLength:((self.length + 4)/5)*8 + 1];
    int len = base32_encode(self.bytes, self.length, data.mutableBytes, data.length);
    data.length = (len <= 0 ? 0 : len);
    return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
}

- (NSString *)base64 {
    NSMutableData *data = [NSMutableData dataWithLength:((self.length + 2) / 3 * 4) + 1];
    int len = base64_encode(self.bytes, self.length, data.mutableBytes, data.length);
    data.length = (len <= 0 ? 0 : len);
    return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
}

- (NSData *)sha1 {
    NSMutableData *data = [NSMutableData dataWithLength:CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(self.bytes, (CC_LONG)self.length, data.mutableBytes);
    return data;
}

- (NSData *)sha256 {
    NSMutableData *data = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(self.bytes, (CC_LONG)self.length, data.mutableBytes);
    return data;
}

#pragma mark - Hex Methods
inline static uint8_t char2byte(unichar c) {
    switch (c) {
        case '0':case '1':case '2':case '3':case '4':case '5':case '6':case '7':case '8':case '9':
            return c - '0';
        case 'a':case 'b':case 'c':case 'd':case 'e':case 'f':
            return c - 'a' + 0x0a;
        case 'A':case 'B':case 'C':case 'D':case 'E':case 'F':
            return c - 'A' + 0x0a;
    }
    return 0;
}

#pragma mark - Base32 Methods
static inline int base32_decode(const uint8_t *ptr, size_t len, uint8_t *outbuf, size_t outsize) {
    int cnt = 0;
    int buffer = 0;
    int bitsLeft = 0;
    for (int i = 0; i < len; i++) {
        uint8_t ch = ptr[i];
        switch (ch) {
            case ' ': case '\t': case '\r': case '\n': case '-':
                continue;
            case 'A':case 'B':case 'C':case 'D':case 'E':case 'F':case 'G':case 'H':case 'I':case 'J':case 'K':case 'L':case 'M':
            case 'N':case 'O':case 'P':case 'Q':case 'R':case 'S':case 'T':case 'U':case 'V':case 'W':case 'X':case 'Y':case 'Z':
                ch -= 'A';
                break;
            case 'a':case 'b':case 'c':case 'd':case 'e':case 'f':case 'g':case 'h':case 'i':case 'j':case 'k':case 'l':case 'm':
            case 'n':case 'o':case 'p':case 'q':case 'r':case 's':case 't':case 'u':case 'v':case 'w':case 'x':case 'y':case 'z':
                ch -= 'a';
                break;
            case '2':case '3':case '4':case '5':case '6':case '7':
                ch -= '2' - 26;
                break;
            case '0': ch = 'O' - 'A'; break;
            case '1': ch = 'L' - 'A'; break;
            case '8': ch = 'B' - 'A'; break;
            default:
                return -1;
        }
        buffer <<= 5;
        buffer |= ch;
        bitsLeft += 5;
        if (bitsLeft >= 8) {
            outbuf[cnt++] = buffer >> (bitsLeft - 8);
            bitsLeft -= 8;
            if (cnt > outsize) {
                break;
            }
        }
    }
    return cnt;
}

static inline int base32_encode(const uint8_t *ptr, size_t len, uint8_t *outbuf, size_t outsize) {
    static const char *tbl = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
    
    int cnt = -1;
    if (len >= 0 && len <= (1 << 28)) {
        cnt = 0;
        if (len > 0) {
            int buffer = ptr[0];
            int next = 1;
            int bitsLeft = 8;
            while (cnt < outsize && (bitsLeft > 0 || next < len)) {
                if (bitsLeft < 5) {
                    if (next < len) {
                        buffer <<= 8;
                        buffer |= ptr[next++] & 0xFF;
                        bitsLeft += 8;
                    } else {
                        int pad = 5 - bitsLeft;
                        buffer <<= pad;
                        bitsLeft += pad;
                    }
                }
                int index = 0x1F & (buffer >> (bitsLeft - 5));
                bitsLeft -= 5;
                outbuf[cnt++] = tbl[index];
            }
        }
        if (cnt < outsize) {
            outbuf[cnt] = '\0';
        }
    }
    return cnt;
}

#pragma mark - Base64 Methods
static const uint8_t pr2six[256] = {
    64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
    64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
    64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 62, 64, 63,
    52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 64, 64, 64, 64, 64, 64,
    64,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
    15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 64, 64, 64, 64, 63,
    64, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
    41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 64, 64, 64, 64, 64,
    64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
    64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
    64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
    64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
    64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
    64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
    64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
    64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64
};

static int base64_decode_len(const uint8_t *ptr) {
    const uint8_t *p = ptr;
    while (pr2six[*(p++)] <= 63);
    return (((int)(p - ptr) + 2) / 4) * 3 + 1;
}

static inline int base64_decode(const uint8_t *ptr, size_t len, uint8_t *outbuf, size_t outsize) {
    const uint8_t * bufin = ptr;
    while (pr2six[*(bufin++)] <= 63);
    int nprbytes = (int)(bufin - (const uint8_t *) ptr) - 1;
    int cnt = 0;
    while (nprbytes > 4) {
        outbuf[cnt++] = (uint8_t) (pr2six[*ptr] << 2 | pr2six[ptr[1]] >> 4);
        outbuf[cnt++] = (uint8_t) (pr2six[ptr[1]] << 4 | pr2six[ptr[2]] >> 2);
        outbuf[cnt++] = (uint8_t) (pr2six[ptr[2]] << 6 | pr2six[ptr[3]]);
        ptr += 4;
        nprbytes -= 4;
    }

    if (nprbytes > 1)
        outbuf[cnt++] = (uint8_t) (pr2six[*ptr] << 2 | pr2six[ptr[1]] >> 4);
    if (nprbytes > 2)
        outbuf[cnt++] = (uint8_t) (pr2six[ptr[1]] << 4 | pr2six[ptr[2]] >> 2);
    if (nprbytes > 3)
        outbuf[cnt++] = (uint8_t) (pr2six[ptr[2]] << 6 | pr2six[ptr[3]]);
    
    return cnt;
}

static inline int base64_encode(const uint8_t *ptr, size_t len, uint8_t *outbuf, size_t outsize) {
    static const char tbl[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";
    int i;
    int cnt = 0;
    for (i = 0; i < len - 2; i += 3) {
        outbuf[cnt++] = tbl[(ptr[i] >> 2) & 0x3F];
        outbuf[cnt++] = tbl[((ptr[i] & 0x3) << 4) | ((int) (ptr[i + 1] & 0xF0) >> 4)];
        outbuf[cnt++] = tbl[((ptr[i + 1] & 0xF) << 2) | ((int) (ptr[i + 2] & 0xC0) >> 6)];
        outbuf[cnt++] = tbl[ptr[i + 2] & 0x3F];
    }
    if (i < len) {
        outbuf[cnt++] = tbl[(ptr[i] >> 2) & 0x3F];
        if (i == (len - 1)) {
            outbuf[cnt++] = tbl[((ptr[i] & 0x3) << 4)];
        } else {
            outbuf[cnt++] = tbl[((ptr[i] & 0x3) << 4) | ((int) (ptr[i + 1] & 0xF0) >> 4)];
            outbuf[cnt++] = tbl[((ptr[i + 1] & 0xF) << 2)];
        }
    }
    if (cnt < outsize) {
        outbuf[cnt] = '\0';
    }
    return cnt;
}


@end
