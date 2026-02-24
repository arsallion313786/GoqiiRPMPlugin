//
//  PersonalInfo.h
//  bleSDKcreation
//
//  Created by Azim on 23/09/22.
//
//

#import <Foundation/Foundation.h>

@interface PersonalInfo : NSObject
@property(nonatomic ,retain)NSString *gender;
@property(nonatomic ,retain)NSString *age;
@property(nonatomic ,retain)NSString *height;
@property(nonatomic ,retain)NSString *weight;
@property(nonatomic ,retain)NSString *stride;
@property(nonatomic ,retain)NSString *userId;
@property(nonatomic ,retain)NSString *firstName;
@property(nonatomic ,retain)NSString *lastName;
@property(nonatomic ,retain)NSString *email;
@property(nonatomic ,retain)NSString *userImageUrl;
@property(nonatomic ,retain)NSString *karma;
@property(nonatomic ,retain)NSString *karmaDonated;
@property(nonatomic ,retain)NSString *userStepsTarget;
@property(nonatomic ,retain)NSString *userDistanceTarget;
@property(nonatomic ,retain)NSString *userCaloriesTarget;
@property(nonatomic ,retain)NSString *userWaterTarget;
@property(nonatomic ,retain)NSString *userSleepTarget;
@property(nonatomic ,retain)NSString *userWeightTarget;
@property(nonatomic ,retain)NSString *totalSteps;
@property(nonatomic ,retain)NSString *totalCalories;
@property(nonatomic ,retain)NSString *updatedTime;
@property(nonatomic ,retain)NSString *joinedSince;
@property(nonatomic ,retain)NSString *groupCount;
@property(nonatomic ,retain)NSString *friendCount;
@property(nonatomic ,retain)NSString *distanceCovered;
@property(nonatomic ,retain)NSString *badgesCount;
@property(nonatomic ,retain)NSString *causesCount;
@property(nonatomic ,retain)NSString *levelName;
@property(nonatomic ,retain)NSString *coachId;
@property(nonatomic ,retain)NSString *city;
@property(nonatomic ,retain)NSString *country;
@property(nonatomic ,retain)NSString *state;
@property(nonatomic ,retain)NSString *address;
@property(nonatomic, retain) NSString *firebaseToken;
//userId, firstName, lastName, email, userImageUrl, karma, userStepsTarget, userDistanceTarget, userCaloriesTarget, userWaterTarget, userSleepTarget, userWeightTarget, totalSteps, totalCalories, updatedTime, joinedSince, groupCount, friendCount, distanceCovered, badgesCount, causesCount, levelName, weight, gender, height, age, coachId
@end
