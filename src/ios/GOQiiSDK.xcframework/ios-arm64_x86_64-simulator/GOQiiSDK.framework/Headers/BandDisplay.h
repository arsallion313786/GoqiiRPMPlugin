//
//  BandDisplay.h
//  bleSDKcreation
//
//  Created by Azim on 23/09/22.
//
//


#import <Foundation/Foundation.h>

@interface BandDisplay : NSObject
@property (readwrite) int distanceUnit; // 1 mile, 0 KM
@property (readwrite) int timeFormat; // 1 12hr, 0 24hr
@property (readwrite) int temperatureFormat; // 1 -> F, 0 -> C
@property (readwrite) int wristSense; // 1 enable, 0 disable
@property (readwrite) int wristHand; // 1 left, 0 right
@property (readwrite) int displayType; // 1 hori, 0 vert
@property (readwrite) int notificationStatus; // 1 enable, 0 disable
@property (readwrite) int brightness; // 1 enable, 0 disable
@property (readwrite) int bloodPressure; // 1 enable, 0 disable
@property (readwrite) int moreOptions; // 1 enable, 0 disable
@property (readwrite) int musicControl; // 1 enable, 0 disable

@end
