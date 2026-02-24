//
//  BandConstants.h
//  bleSDKcreation
//
//  Created by Azim on 23/09/22.
//
//

#ifndef BandConstants_h
#define BandConstants_h

#define constGOQii_HC @"GOQiiHC"
#define constGOQii_STRIDE @"GOQiiSTRIDE"
#define constGOQii_EXPLORE @"GOQii-RunGPS"
#define constGOQii_VITAL_2_0 @"GOQiiVital2.0"
#define constGOQii_VITAL_2 @"GOQiiVital2"
#define constGOQii_VITAL_ECG @"GOQiiVitalECG"
#define constGOQii_VITAL_TEMPERATURE_3D @"GOQiiVital3D"
#define constGOQii_VITAL_TEMPERATURE_3 @"GOQiiVital3"
#define constGOQii_BALANCE @"GOQiiBalance"
#define constGOQii_CONTOUR @"GOQiiContour"
#define constGOQii_ESSENTIAL @"GOQiiEssential"
#define constGOQii_SMART_VITAL @"GOQiiSmartVital"
#define constGOQii_VITAL_4 @"GOQiiVital4"
#define constGOQii_VITAL_40 @"GOQiiVital4.0"
#define constGOQii_SMART_VITAL_JUNIOR @"GOQiiSVJunior"
#define constGOQii_SV_HD @"GOQiiSV2.0"
#define constGOQii_SV_PLUS @"GOQiiSVPLUS"
#define constGOQii_SV_LITE @"GOQiiSVLITE"
//#define constGOQii_SV_20MAX @"GOQiiSV2.0MAX"
#define constGOQii_SV_20MAX @"GOQiiSmartVitalSr"
#define constGOQii_SV_2MAX @"GOQiiSV2MAX"
#define constGOQii_SV_MAX @"GOQiiSVMAX"
#define constGOQii_SV_2HD_R @"GOQiiSV2HD_R"
#define constGOQii_SV_2_R @"GOQiiSV2_R"
#define constGOQii_SV_2_S @"GOQiiSV2_S"
#define constGOQii_SV_SMART_O2 @"GOQiiSmartO2"
#define constGOQii_SV_ULTRA @"GOQiiSVULTRA"
#define constGOQii_STREAM @"GOQiiStream"
#define constGOQii_STREAM2 @"R7"
#define V3_BANDNAME @"GOQiiCHR"
#define V3_VITAL @"GOQiiVital"
#define V3_CRUX @"GOQiiCrux"
#define V3_BEAT @"GOQiiBeat"
#define TRACKER_NAME @"TRACKER_NAME"
#define BAND_FIRMWARE_VERSION @"BAND_FIRMWARE_VERSION"
#define USER_GENDER @"USER_GENDER"
#define IS_DEVICE_SCAN_IN_PROGRESS @"IS_DEVICE_SCAN_IN_PROGRESS"
#define IS_DEVICE_SYNCING_IN_PROGRESS @"IS_DEVICE_SYNCING_IN_PROGRESS"
#define MAC_ADDRESS @"MAC_ADDRESS"
#define DEVICE_SENSOR_TYPE @"DEVICE_SENSOR_TYPE"
#define BAND_CONTINUOUS_HR_SET @"BAND_CONTINUOUS_HR_SET"
#define USER_ID @"USER_ID"
#define USER_STEPS_TARGET @"USER_STEPS_TARGET"

#define SAVE_DAILY_DEVICE_ACTIVITY_NOTIFICATION @"SAVE_DAILY_DEVICE_ACTIVITY_NOTIFICATION"

#define USER_PREFERENCE_TIME_FORMAT @"USER_PREFERENCE_TIME_FORMAT"
#define USER_PREFERENCE_DISTANCE_UNIT @"USER_PREFERENCE_DISTANCE_UNIT"

#define GET_NEW_DAILY_DEVICE_ACTIVITY_NOTIFICATION @"GET_NEW_DAILY_DEVICE_ACTIVITY_NOTIFICATION"
#define GET_NEW_DEVICE_SLEEP_NOTIFICATION_V3 @"GET_NEW_DEVICE_SLEEP_NOTIFICATION_V3"
#define NEW_HEART_RATE_ACTIVITIES_FOR_SERVER @"NEW_HEART_RATE_ACTIVITIES_FOR_SERVER"
#define  GET_NEW_DEVICE_BP_NOTIFICATION_V3 @"GET_NEW_DEVICE_BP_NOTIFICATION_V3"
#define  UPDATE_BP_STATUS_V3 @"UPDATE_BP_STATUS_V3"
#define  UPDATE_ECG_STATUS_V3 @"UPDATE_ECG_STATUS_V3"

//API
//https://dev-nikhil-api.goqii.com/rpm/add_glucose
//#define DOWNLOAD_CERTIFICATE @"https://pinning.goqii.com/ruser/ssl"


#define VERIFY @"bajajallianz/verify_otp_v2?"
#define ADD_DAILY_ACTIVITY @"band/add_daily_activity?"
#define ADD_MULTIPLE_ACTIVITY @"activity/add_multiple_activity?"
#define DEVICE_AVAILABLITY @"user/device_availability?"
#define CALL_SOS @"band/call_sos?"
#define UPDATE_LASTSYNC_DATE @"user/device_last_syn?"

#define DOWNLOAD_CERTIFICATE @"https://dev-nikhil-api.goqii.com/rpm/ssl"
#define LINK_DEVICE @"https://dev-nikhil-api.goqii.com/rpm/link_device?"
#define UNLINK_DEVICE @"https://dev-nikhil-api.goqii.com/rpm/unlink_device?"
#define ADD_GLUCOSE @"https://dev-nikhil-api.goqii.com/rpm/add_glucose?"
#define FETCH_GLUCOSE_RECORD @"https://dev-nikhil-api.goqii.com/rpm/fetch_glucose_record?"

typedef NS_ENUM(NSUInteger, CoreType){
    
    GOQii_DEFAULT = 100,   // 6 below firmware version
    GOQii_V2 = 0,  //  6 to 6.2
    GOQii_HC = 1,  // 8 to 8.2
    GOQii_CHR = 2,
    GOQii_VITAL = 3,
    GOQii_CRUX = 4,
    GOQii_BEAT = 5,
    GOQii_STRIDE = 6,
    GOQii_EXPLORE = 7,
    GOQii_VITAL_2 = 8,
    GOQii_VITAL_ECG = 9,
    GOQii_VITAL_TEMPERATURE = 10,
    GOQii_SMART_VITAL = 11,
    GOQii_VITAL_4 = 12,
    GOQii_SMART_VITAL_JUNIOR = 13,
    GOQii_SV_HD = 14,
    GOQii_SV_PLUS = 15,
    GOQii_SV_MAX = 16,
    GOQii_SV_LITE = 17,
    GOQii_SV_2 = 18,
    GOQii_SV_2_MAX = 19,
    GOQii_SV_SMART_O2 = 20,
    GOQii_SV_ULTRA = 21,
    GOQii_STREAM = 22
    
} ;
typedef NS_ENUM(NSUInteger, GOQiiDevices) {
    
    GOQii_TRACKER = 0,
    GOQii_SCALE = 1,
    GOQii_GLUCO = 2,
    GOQii_SMART_SKIP = 3
    
    
} ;

typedef NS_ENUM(NSUInteger, WeightScaleType){
    
    GOQii_BALANCE = 0,   // Contour
    GOQii_ESSENTIAL = 1
    
} ;

// Sync Constants
typedef NS_ENUM(NSUInteger, TrackerSyncType){
    
//    Temperature 1 and 2 // BodyTemperatureData
//    Sleep
//    Steps
//    HR 1 and 2
//    Spo2
//    Exercise

    
    SYNC_TEMPERATURE1 = 1,
    SYNC_TEMPERATURE2 = 2,
    SYNC_SLEEP = 3,
    SYNC_STEP = 4,
    SYNC_HR_DETAILS1 = 5,
    SYNC_HR_DETAILS2 = 6,
    SYNC_SPO2 = 7,
    SYNC_ACTIVITY = 8,
    SYNC_BP = 9,
    SYNC_ECG = 10,
    SYNC_FINISH = 11
    
} ;

typedef NS_ENUM(NSUInteger, UploadDataType){

    UPLOAD_TEMPERATURE = 1,
    UPLOAD_SLEEP = 2,
    UPLOAD_STEP = 3,
    UPLOAD_HR = 4,
    UPLOAD_SPO2 = 5,
    UPLOAD_ACTIVITY = 6,
    UPLOAD_BP = 7,
    UPLOAD_ECG = 8,
    UPLOAD_SYNC = 9,
    UPLOAD_FINISH = 10
    
} ;
#endif /* BandConstants_h */
