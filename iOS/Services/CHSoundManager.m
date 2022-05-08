//
//  CHSoundManager.m
//  iOS
//
//  Created by WizJin on 2022/3/12.
//

#import "CHSoundManager.h"
#import <AudioToolbox/AudioToolbox.h>
#import "CHAudioPlayer.h"

@interface CHSoundManager ()

@property (nonatomic, readonly, strong) NSURL *soundDirURL;

@end

@implementation CHSoundManager

+ (instancetype)soundManagerWithGroupId:(NSString *)groupId {
    return [[self alloc] initWithGroupId:groupId];
}

- (instancetype)initWithGroupId:(NSString *)groupId {
    if (self = [super init]) {
        _soundDirURL = [NSFileManager.defaultManager.URLForLibraryDirectory URLByAppendingPathComponent:@"Sounds"];
        @weakify(self);
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
            @strongify(self);
            [self syncSystemSounds];
        });
    }
    return self;
}

- (void)playWithName:(NSString *)name {
    if (name.length <= 0) {
        AudioServicesPlayAlertSound(kCHDefaultNotificationSoundID);
    } else {
        NSURL *fileUrl = [self.soundDirURL URLByAppendingPathComponent:[name stringByAppendingString:@".caf"]];
        [CHAudioPlayer.shared playWithURL:fileUrl title:name];
    }
}

- (NSArray<NSString *> *)soundNames {
    NSMutableArray<NSString *> *files = [NSMutableArray new];
    NSString *dirPath = self.soundDirURL.path;
    NSFileManager *fm = NSFileManager.defaultManager;
    for (int i = 0; i < sizeof(soundtbl)/sizeof(soundtbl[0]); i++) {
        NSString *name = [NSString stringWithCString:soundtbl[i].name encoding:NSUTF8StringEncoding];
        NSString *filePath = [dirPath stringByAppendingPathComponent:[name stringByAppendingString:@".caf"]];
        if ([fm fileExistsAtPath:filePath]) {
            [files addObject:name];
        }
    }
    return files;
}

#pragma mark - Private Methods
- (void)syncSystemSounds {
    CHLogD("Start sync system notification sounds.");
    NSURL *dirURL = self.soundDirURL;
    NSString *srcDir = @"/System/Library/Audio/UISounds";
    NSFileManager *fm = NSFileManager.defaultManager;
    [fm fixDirectory:dirURL];
    for (int i = 0; i < sizeof(soundtbl)/sizeof(soundtbl[0]); i++) {
        NSString *dstPath = [dirURL.path stringByAppendingFormat:@"/%s.caf", soundtbl[i].name];
        if (![fm fileExistsAtPath:dstPath]) {
            NSString *srcPath = [srcDir stringByAppendingFormat:@"/%s", soundtbl[i].path];
            if ([fm isReadableFileAtPath:srcPath]) {
                NSError *error = nil;
                if (![fm copyItemAtPath:srcPath toPath:dstPath error:&error]) {
                    CHLogW("Sync notification sound failed: %s", error.description.cstr);
                }
            }
        }
        NSURL *fileUrl = [NSURL fileURLWithPath:dstPath];
        fileUrl.dataProtoction = NSURLFileProtectionCompleteUntilFirstUserAuthentication;
    }
}

typedef struct sound_item {
    const char *name;
    const char *path;
} sound_item_t;

// REF: https://www.theiphonewiki.com/wiki//System/Library/Audio/UISounds
static const sound_item_t soundtbl[] = {
    { "alarm",                  "alarm.caf" },
    { "anticipate",             "New/Anticipate.caf" },
    { "bell",                   "sms-received5.caf" },
    { "bloom",                  "New/Bloom.caf" },
    { "calypso",                "New/Calypso.caf" },
    { "chime",                  "sms-received2.caf" },
    { "choo",                   "New/Choo_Choo.caf" },
    { "descent",                "New/Descent.caf" },
    { "electronic",             "sms-received6.caf" },
    { "fanfare",                "New/Fanfare.caf" },
    { "glass",                  "sms-received3.caf" },
    { "go_to_sleep",            "go_to_sleep_alert.caf" },
    { "health_notification",    "health_notification.caf" },
    { "horn",                   "sms-received4.caf" },
    { "ladder",                 "New/Ladder.caf" },
    { "minuet",                 "New/Minuet.caf" },
    { "multiway_invitation",    "nano/MultiwayInvitation.caf" },
    { "new_mail",               "new-mail.caf" },
    { "news_flash",             "New/News_Flash.caf" },
    { "noir",                   "New/Noir.caf" },
    { "payment_success",        "payment_success.caf" },
    { "sent_mail",              "mail-sent.caf" },
    { "sent_sms",               "SentMessage.caf" },
    { "shake",                  "shake.caf" },
    { "sherwood_forest",        "New/Sherwood_Forest.caf" },
    { "spell",                  "New/Spell.caf" },
    { "suspense",               "New/Suspense.caf" },
    { "telegraph",              "New/Telegraph.caf" },
    { "tiptoes",                "New/Tiptoes.caf" },
    { "typewriters",            "New/Typewriters.caf" },
    { "update",                 "New/Update.caf" },
};


@end
