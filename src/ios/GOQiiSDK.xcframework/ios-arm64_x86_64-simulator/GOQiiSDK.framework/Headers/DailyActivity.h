//
//  DailyActivity.h
//  GOQii
//
//  Created by Prashant Thakur on 05/03/14.
//
//

#import <Foundation/Foundation.h>

@interface DailyActivity : NSObject{
    int l_dailyDeviceActivityId;
    int dailyActivityId;
    int userId;
    int totalActiveTime;
    int karmaPoint;
    int totalSteps;
    int totalCalories;
    int totalDistance;
    NSString * logDate;
    NSString * status;
}

@property int l_dailyDeviceActivityId;
@property int dailyActivityId;
@property int userId;
@property int totalActiveTime;
@property int karmaPoint;
@property int totalSteps;
@property int totalCalories;
@property int totalDistance;
@property int healthKitSteps;
@property int cumulativeSteps;
@property int otherSteps;
@property (nonatomic ,retain)NSString *sum96stepsv2;
@property (nonatomic ,retain)NSString *sum96stepsv3;
@property (nonatomic ,retain)NSString *type;
@property (nonatomic ,retain)NSString *logDate;
@property (nonatomic ,retain)NSString *createdTime;
@property (nonatomic ,retain) NSString *status;
@property (nonatomic ,retain) NSString *source;
@property (nonatomic ,retain) NSString *privacyType;
@property(nonatomic, retain)NSString *likeByMe;
@property(readwrite)BOOL commentByMe;
@property(readwrite)BOOL isV2;
@property(readwrite)BOOL isTrackerData;
@property (nonatomic ,retain)NSString *lightSleep;
@property (nonatomic ,retain)NSString *deepSleep;
@property (nonatomic ,retain)NSString *almostAwake;
@property (nonatomic ,retain)NSString *REMSleep;
@property (nonatomic ,retain)NSString *totalSleep;


-(DailyActivity*)init;

@end
