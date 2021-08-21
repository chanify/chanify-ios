//
//  NotificationService.m
//  NotificationService
//
//  Created by WizJin on 2021/2/8.
//

#import "NotificationService.h"
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
    CHMessageProcessFlags flags = 0;
    NSData *data = nil;
    NSString *mid = nil;
    NSString *uid = [CHMessageModel parsePacket:self.attemptContent.userInfo mid:&mid data:&data];
    if (uid.length > 0 && mid.length > 0 && data.length > 0) {
        CHNSDataSource *dbsrc = self.class.sharedDB;
        CHMessageModel *model = [dbsrc pushMessage:data mid:mid uid:uid flags:&flags];
        if (!(flags&CHMessageProcessFlagNoAlert)) {
            self.attemptContent.badge = @([dbsrc nextBadgeForUID:uid]);
            if (model != nil) {
                [model formatNotification:self.attemptContent];
            }
        }
    }
    if (!(flags&CHMessageProcessFlagNoAlert)) {
        self.contentHandler(self.attemptContent);
    } else {
        self.contentHandler([UNNotificationContent new]);
    }
}

- (void)serviceExtensionTimeWillExpire {
    self.contentHandler(self.attemptContent);
}


@end
