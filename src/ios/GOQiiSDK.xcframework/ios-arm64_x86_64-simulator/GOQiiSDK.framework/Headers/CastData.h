//
//  CastData.h
//  GOQiiNative
//
//  Created by Divum on 6/18/15.
//  Copyright (c) 2015 Divum. All rights reserved.
//

#import <Foundation/Foundation.h>
@class EcgDbModel;
@interface CastData : NSObject
+(NSMutableArray*)getArrayOfDictionaryFromDeviceActivites:(NSArray*)activitiesArray;
+(NSMutableArray*)getArrayOfDictionaryFromDailyDeviceActivites:(NSArray*)activitiesArray;
+(NSMutableArray*)getArrayOfDictionaryFromPhoneActivites:(NSArray*)activitiesArray;
+(NSMutableArray*)getArrayOfDictionaryFromPhoneActivitesForDelete:(NSArray*)activitiesArray;
+(NSMutableArray*)getArrayOfDictionaryFromFoods:(NSArray*)foodsArray;
+(NSMutableArray*)getArrayOfDictionaryFromSleeps:(NSArray*)sleepsArray;
+(NSMutableArray*)getArrayOfDictionaryFromWaters:(NSArray*)watersArray;
+(NSMutableArray*)getArrayOfDictionaryFromWeights:(NSArray*)weightsArray;
+(NSMutableArray*)getArrayOfDictionaryFromTargets:(NSArray*)targetsArray;
+(NSMutableArray*)getArrayOfDictionaryFromTemperature:(NSArray*)temperatureArray;

+(NSMutableArray*)getNewPhoneActivitiesFrom:(NSArray*)fulldataArray;
+(NSMutableArray*)getUpdatePhoneActivitiesFrom:(NSArray*)fulldataArray;

+(NSMutableArray*)getNewECG:(NSArray*)dataArray;

+(NSMutableArray*)getNewFoodsFrom:(NSArray*)fulldataArray;
+(NSMutableArray*)getUpdateFoodsFrom:(NSArray*)fulldataArray;

+(NSMutableArray*)getNewSleepsFrom:(NSArray*)fulldataArray;
+(NSMutableArray*)getUpdateSleepsFrom:(NSArray*)fulldataArray;

+(NSMutableArray*)getNewWatersFrom:(NSArray*)fulldataArray;
+(NSMutableArray*)getUpdateWatersFrom:(NSArray*)fulldataArray;

+(NSMutableArray*)getNewWeightsFrom:(NSArray*)fulldataArray;
+(NSMutableArray*)getUpdateWeightsFrom:(NSArray*)fulldataArray;
//+(NSMutableArray*)getDictionaryFromGeneratedForDelete:(ActivityFeed *)feed;
+(NSMutableArray*)getArrayOfDictionaryFromGeneratedForDelete:(NSArray*)feedsArray;
@end
