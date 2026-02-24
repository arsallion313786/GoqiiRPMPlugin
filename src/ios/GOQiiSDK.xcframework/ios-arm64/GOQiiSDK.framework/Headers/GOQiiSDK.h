//
//  GOQiiSDK.h
//  GOQiiSDK
//
//  Created by Azim on 30/09/22.
//

#import <Foundation/Foundation.h>

//! Project version number for GOQiiSDK.
FOUNDATION_EXPORT double GOQiiSDKVersionNumber;

//! Project version string for GOQiiSDK.
FOUNDATION_EXPORT const unsigned char GOQiiSDKVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <GOQiiSDK/PublicHeader.h>


#import <GOQiiSDK/DeviceSleepV3.h>
#import <GOQiiSDK/DailyActivity.h>
#import <GOQiiSDK/DeviceExerciseV3.h>
#import <CoreData/CoreData.h>
#import <GOQiiSDK/NSDate+Utils.h>
#import <GOQiiSDK/RSAEnc.h>
#import <GOQiiSDK/JSONParser.h>
#import <GOQiiSDK/AFNetworking.h>
#import <GOQiiSDK/BLE.h>
#import <GOQiiSDK/CastData.h>
//#import <GOQiiSDK/UICKeyChainStore.h>

///Users/azimnadaf/Documents/GOQiiSDK/UICKeyChainStore
typedef NS_ENUM(NSUInteger, CompletionResultType) {
    Success = 0,
    Failure = 1
    
};
