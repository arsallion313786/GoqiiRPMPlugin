//
//  DeviceActivity.h
//  GOQii
//
//  Created by Prashant Thakur on 05/03/14.
//
//

#import <Foundation/Foundation.h>

@interface DeviceActivity : NSObject{
    
    int l_activityId;
    int activityId;
    int userId;
    NSString * createdTime;
    NSString * logDate;
    int calories;
    float distance;
    int duration;
    NSString * description;
    NSString * startTime;
    NSString * endTime;
    int steps;
    int offset;
    int lightSleep;
    int deepSleep;
    int almostAwake;
    int REMSleep;
    int year;
    int month;
    int activityType;
    NSString * status;
    int s1;
    int s2;
    int s3;
    int s4;
    int s5;
    int s6;
    int s7;
    int s8;
    
}

@property int l_activityId;
@property int activityId;
@property int userId;
@property(nonatomic, retain) NSString * createdTime;
@property(nonatomic, retain) NSString * logDate;
@property int calories;
@property float distance;
@property int duration;
@property(nonatomic, retain) NSString * description;
@property(nonatomic, retain) NSString * startTime;
@property(nonatomic, retain) NSString * endTime;
@property int steps;
@property int offset;
@property int lightSleep;
@property int deepSleep;
@property int almostAwake;
@property int REMSleep;
@property int year;
@property int month;
@property int activityType;
@property(nonatomic, retain) NSString * status;
@property int s1;
@property int s2;
@property int s3;
@property int s4;
@property int s5;
@property int s6;
@property int s7;
@property int s8;
@property(nonatomic ,retain)NSString *source;
@property(nonatomic ,retain)NSString *privacyType;
@property(nonatomic, retain)NSString *likeByMe;
@property(readwrite)BOOL commentByMe;
@property (nonatomic, retain) NSString *logFrom,*heartData;
@property (nonatomic ,retain)NSString *gpsData, *gpsDerivedData;
-(DeviceActivity*)init;

@end
