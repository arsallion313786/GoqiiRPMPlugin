//
//  DeviceSleepV3.h
//  GOQiiSDK
//
//  Created by Azim on 30/09/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DeviceSleepV3: NSObject

@property int activityId,l_activityId,ID1,ID2,lightSleep,deepSleep,almostAwake,s1,s2,s3,s4,s5,s6,s7,s8,activityType,descriptionCount;
@property(nonatomic, retain)NSString *createdTime, *logDate, *logDateTime, *logEndTime, *description, *status;
@end

NS_ASSUME_NONNULL_END
