//
//  DeviceActivityV3.h
//  GOQiiNative
//
//  Created by IRSHAD-GOQii on 07/07/18.
//  Copyright © 2018 GOQii. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DeviceActivityV3 : NSObject
@property int l_activityId;
@property int activityId;
@property int userId,ID1,ID2;
@property(nonatomic, retain) NSString * createdTime;
@property(nonatomic, retain) NSString * logDate;
@property(nonatomic, retain) NSString * newlogDate; // yyyy-mm-dd HH-MM
@property(nonatomic, retain) NSString * startTime;
@property(nonatomic, retain) NSString * endTime;
@property int steps;
@property float distance;
@property int calories;
@property int activityType;
@property(nonatomic, retain) NSString * description;
@property(nonatomic, retain) NSString * status;
@end








