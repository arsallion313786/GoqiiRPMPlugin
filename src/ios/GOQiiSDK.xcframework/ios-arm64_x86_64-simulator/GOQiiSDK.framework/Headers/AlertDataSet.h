//
//  AlertDataSet.h
//  bleSDKcreation
//
//  Created by Azim on 23/09/22.
//
//

#import <Foundation/Foundation.h>
#import "AlarmConstants.h"
#define DaysBtnselectedColor [UIColor colorWithRed:0 green:176.0/255.0 blue:235.0/255.0 alpha:1]
#define DaysBtnUnselectedColor [UIColor colorWithRed:162.0/255.0 green:234.0/255.0 blue:254.0/255.0 alpha:1]



@interface AlertDataSet : NSObject
@property(nonatomic,retain)NSString *duration;
@property(nonatomic,retain)NSString *startHourStr;
@property(nonatomic,retain)NSString *endHourStr;
@property(nonatomic,retain)NSString *napStartHourStr;
@property(nonatomic,retain)NSString *napEndHourStr;
@property(nonatomic,retain)NSString *repeatStr;
@property(readwrite)DaysType daystype;

@property                   int startHour;
@property                   int startMin;
@property                   int stopHour;
@property                   int stopMinute;
@property                   int napStartHour;
@property                   int napStartMin;
@property                   int napStopHour;
@property                   int napStopMinute;
@property                   int enable;
@property                   int mondayEnabled;
@property                   int tuedayEnabled;
@property                   int wednesdayEnabled;
@property                   int thursdayEnabled;
@property                   int fridayEnabled;
@property                   int saturdayEnabled;
@property                   int sundayEnabled;


@end
