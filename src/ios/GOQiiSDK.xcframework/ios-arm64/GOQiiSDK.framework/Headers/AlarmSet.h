//
//  AlarmSet.h
//  bleSDKcreation
//
//  Created by Azim on 23/09/22.
//

#import <Foundation/Foundation.h>
#import "AlarmConstants.h"
typedef enum {
    Inactive,
    Active
    
}Alarmstatus;


@interface AlarmSet : NSObject
@property(nonatomic,retain) NSString    *time;
@property(nonatomic,retain) NSString    *repeatStr;
@property(nonatomic, retain)NSString *alarmName;
@property(readwrite)        Alarmstatus state;
@property(readwrite)        DaysType daystype;
@property                   int alarmNumber;
@property                   int alarmEnable;
@property                   int hour;
@property                   int minute;
@property                   int second;
@property                   int mondayEnabled;
@property                   int tuedayEnabled;
@property                   int wednesdayEnabled;
@property                   int thursdayEnabled;
@property                   int fridayEnabled;
@property                   int saturdayEnabled;
@property                   int sundayEnabled;
@end
