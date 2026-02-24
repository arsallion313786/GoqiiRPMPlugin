//
//  DeviceExerciseV3.h
//  GOQiiSDK
//
//  Created by Azim on 30/09/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DeviceExerciseV3: NSObject
@property int activityid,l_activityid, ID1, ID2, steps, calories, duration, excerciseTime, userID;
@property float distance,heightAspectRatio;
@property (nonatomic, retain) NSString *logDate, *dateTime,*exerciseType,*isDeleted,*exerciseFrom,*status,*endTime, *source,*createdTime,*logFrom,*heartRateData,*gpsDerivedData, *intensity, *privacy,*unit,*lat,*lng,*actvityGoalTarget,*description;
@end


NS_ASSUME_NONNULL_END
