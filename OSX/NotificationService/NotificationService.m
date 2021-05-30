//
//  NotificationService.m
//  NotificationService
//
//  Created by WizJin on 2021/5/30.
//

#import "NotificationService.h"
#import "CHNSDataSource.h"
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
        dbsrc = [CHNSDataSource dataSourceWithURL:[NSFileManager.defaultManager URLForGroupId:@kCHAppOSXGroupName path:@kCHDBNotificationServiceName]];
    });
    return dbsrc;
}

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
    self.contentHandler = contentHandler;
    self.attemptContent = [request.content mutableCopy];
    NSData *data = nil;
    NSString *mid = nil;
    NSString *uid = [CHMessageModel parsePacket:self.attemptContent.userInfo mid:&mid data:&data];
    if (uid.length > 0) {
        CHNSDataSource *dbsrc = self.class.sharedDB;
        self.attemptContent.badge = @([dbsrc nextBadgeForUID:uid]);
        if (mid.length > 0 && data.length > 0) {
            CHMessageModel *msg = [dbsrc pushMessage:data mid:mid uid:uid store:YES];
            if (msg != nil) {
                [msg formatNotification:self.attemptContent];
            }
        }
    }
    self.contentHandler(self.attemptContent);
}

- (void)serviceExtensionTimeWillExpire {
    self.contentHandler(self.attemptContent);
}


@end
