//
//  MainDatabaseManager.h
//  bleSDKcreation
//
//  Created by Azim on 28/09/22.
//

#import <Foundation/Foundation.h>
#import "DailyActivity.h"
#import "BandConstants.h"
#import "DeviceActivityV3.h"
#import "DeviceExerciseV3.h"
#import "DeviceSleepV3.h"
#import "BLE.h"
#import "GOQiiSDK/GOQiiSDK-Swift.h"


NS_ASSUME_NONNULL_BEGIN

@interface MainDatabaseManager : NSObject{
    NSOperationQueue *queue;
}

+ (instancetype)sharedInstance;

-(void)saveDailyDeviceActivity:(DailyActivity*)data;
-(void)saveHeartRateActivityArrayIntoDB:(NSMutableArray *) hrActivity;
-(void)saveHeartRateActivityIntoDB:(NSDictionary *)hrActivity;
-(void)saveTempratureIntoDB:(NSDictionary *)dict;
-(void)saveBloodPressure:(NSDictionary*)bpObj;
-(void)saveSpo2IntoDB:(NSDictionary *)dict;
-(NSString *)getAvrageTempratureFor:(NSString *)strDate and:(NSString *) endDate;
-(void)saveDetailSleepActivityDataV3:(NSDictionary*)data;
-(void)saveExerciseActivityDataV3:(DeviceExerciseV3*)data;
-(void)sleepDataConvertDatAndSaveInDB:(DeviceSleepV3*)sleep;
-(void)saveECGData:(NSDictionary *)dict andData:(NSMutableArray *)hrvData andTime:(NSString *)createdTime andSlot:(NSString *)slotNo;
-(BOOL)isECGRecordExisting:(NSDictionary*)data;
-(void) createTemperatureJsonFile:(NSString *) jsonString;
//-(void)fetchUserInfo:(NSString *)mobile and:(NSString *)encryUserId;
-(void)syncJC:(TrackerSyncType ) type;
-(void)checkDeviceAvalability:(NSString *)macAddress;
-(void)uploadUserLocationForSOS: (NSString *)lat and:(NSString *)lon and:(NSString *)type and:(NSDictionary *)dataDict;
-(void)removeMACAddressFromAccount;
-(void)removeMACAddressForUser:(NSString *)encUserId;
-(void)addGlucometerMACAddressToAccount;
@end

NS_ASSUME_NONNULL_END
