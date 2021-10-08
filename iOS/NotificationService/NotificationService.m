//
//  NotificationService.m
//  NotificationService
//
//  Created by WizJin on 2021/2/8.
//

#import "NotificationService.h"
#import <Intents/Intents.h>
#import "CHIconView.h"
#import "CHNSDataSource.h"
#import "CHTimelineDataSource.h"
#import "CHTP.pbobjc.h"

@interface NotificationService ()

@property (nonatomic, strong) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property (nonatomic, strong) UNMutableNotificationContent *attemptContent;

@end

@implementation NotificationService

+ (CHNSDataSource *)sharedDB {
    static CHNSDataSource *dbsrc;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dbsrc = [CHNSDataSource dataSourceWithURL:[NSFileManager.defaultManager URLForGroupId:@kCHAppGroupName path:@kCHDBNotificationServiceName]];
    });
    return dbsrc;
}

+ (CHTimelineDataSource *)sharedTimelineDB {
    static CHTimelineDataSource *dbsrc;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dbsrc = [CHTimelineDataSource dataSourceWithURL:[NSFileManager.defaultManager URLForGroupId:@kCHAppTimelineGroupName path:@kCHDBTimelineName]];
    });
    return dbsrc;
}

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
    self.contentHandler = contentHandler;
    self.attemptContent = [request.content mutableCopy];
    UNNotificationContent *notificationContent = self.attemptContent;
    NSData *data = nil;
    NSString *mid = nil;
    NSString *uid = [CHMessageModel parsePacket:self.attemptContent.userInfo mid:&mid data:&data];
    if (uid.length > 0 && mid.length > 0 && data.length > 0) {
        CHMessageProcessFlags flags = 0;
        CHNSDataSource *dbsrc = self.class.sharedDB;
        CHMessageModel *model = [dbsrc pushMessage:data mid:mid uid:uid flags:&flags];
        if (model != nil) {
            if (!(flags&CHMessageProcessFlagNoAlert)) {
                self.attemptContent.badge = @([dbsrc nextBadgeForUID:uid]);
                [model formatNotification:self.attemptContent];
            }
            [self.class.sharedTimelineDB upsertUid:uid from:model.from model:model.timeline];
        }
        if (flags&CHMessageProcessFlagNoAlert) {
            notificationContent = [UNNotificationContent new];
        } else {
            if (@available(iOS 15.0, *)) {
                notificationContent = setNotificationContentIcon(self.attemptContent, @"sys://sun.min");
            }
        }
    }
    self.contentHandler(notificationContent);
}

- (void)serviceExtensionTimeWillExpire {
    self.contentHandler(self.attemptContent);
}

static inline NSURL *loadIconURL(NSString *icon) {
    NSURL *res = nil;
    NSFileManager *fm = NSFileManager.defaultManager;
    NSString *name = [icon dataUsingEncoding:NSUTF8StringEncoding].sha1.hex;
    NSURL *dir = [fm.temporaryDirectory URLByAppendingPathComponent:@"icons"];
    NSURL *url = [dir URLByAppendingPathComponent:name];
    if ([fm isReadableFileAtPath:url.path]) {
        res = url;
    } else if ([fm fixDirectory:dir]) {
        CHIconView *iconView = [[CHIconView alloc] initWithFrame:CGRectMake(0, 0, 120, 120)];
        iconView.image = icon;
        NSData *data = UIImagePNGRepresentation(iconView.saveImage);
        if ([data writeToURL:url atomically:YES]) {
            res = url;
        }
    }
    return res;
}

static inline UNNotificationContent *setNotificationContentIcon(UNMutableNotificationContent *notificationContent, NSString *icon) API_AVAILABLE(ios(15.0)) {
    NSURL *iconURL = loadIconURL(icon);
    if (iconURL != nil) {
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:notificationContent.userInfo];
        [userInfo setValue:icon forKey:@"icon"];
        notificationContent.userInfo = userInfo;

        NSPersonNameComponents *personName = [NSPersonNameComponents new];
        personName.nickname = notificationContent.title ?: @"";
        INImage *avatar = [INImage imageWithURL:iconURL];
        INPersonHandle *personHandle = [[INPersonHandle alloc] initWithValue:@"" type:INPersonHandleTypeUnknown];
        INPerson *sender = [[INPerson alloc] initWithPersonHandle:personHandle nameComponents:personName displayName:personName.nickname image:avatar contactIdentifier:nil customIdentifier:nil isMe:NO];
        INPerson *me = [[INPerson alloc] initWithPersonHandle:personHandle nameComponents:nil displayName:nil image:nil contactIdentifier:nil customIdentifier:nil isMe:YES];
        INSendMessageIntent *intent = [[INSendMessageIntent alloc] initWithRecipients:@[me] outgoingMessageType:INOutgoingMessageTypeOutgoingMessageText content:notificationContent.body speakableGroupName:nil conversationIdentifier:notificationContent.threadIdentifier serviceName:nil sender:sender attachments:nil];
        INInteraction *interaction = [[INInteraction alloc] initWithIntent:intent response:nil];
        interaction.direction = INInteractionDirectionIncoming;
        [interaction donateInteractionWithCompletion:nil];
        NSError *error = nil;
        UNNotificationContent *content = [notificationContent contentByUpdatingWithProvider:intent error:&error];
        if (error == nil && content != nil) {
            return content;
        }
    }
    return notificationContent;
}


@end
