//
//  BLE.h
//  bleSDKcreation
//
//  Created by Azim on 23/09/22.
//
#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <UIKit/UIKit.h>
#import "BLEDevice.h"
#import "BLE_Constants.h"
#import "PersonalInfo.h"
#import "AlarmSet.h"
#import "AlertDataSet.h"
#import "BandDisplay.h"
#import "GOQiiBandType.h"
#import "BandConstants.h"
#import "Weather.h"
#import "BPRange.h"
#import "CommandList.h"
#import "DailyActivity.h"
#import "DeviceActivity.h"
#import "DeviceActivityV3.h"
#pragma mark - BLECoreDelegates
@protocol BLECoreDelegates
-(void)didBluetoothTurnedOff;
-(void)didBluetoothTurnedOn;
-(void)didReceiveDeviceList:(NSArray*)devicelist;
-(void)didPeripheralConnectSuccessful:(CBPeripheral*)peripheral bleDevice:(BLEDevice *)device;
-(void)didPeripheralConnectFailure:(CBPeripheral*)peripheral;
-(void)didCharacteristicsDscovered:(BLEDevice *)device;
-(void)didNotCharacteristicsDscovered:(BLEDevice *)device;
-(void)askForBluetoothPermission;
-(void)didDeviceBindSuccessfulWithMacAddress;
-(void)didSendBondRequest;
-(void)didAcceptBondRequest;
-(void)didReceiveBandTimeUpdated;
-(void)receivedFirmwareVersion:(NSString*)firmware;
-(void)receivedTimeFormat:(NSString*)format;
-(void)didSetTarget:(BOOL)isSuccess;
-(void)didEnableSpo2DataRead:(BOOL)isSuccess;
-(void)verifyCode:(int)code;
-(void)didReceiveBandStatus:(NSString *)message andStatus:(BOOL)Status;
-(void)fallDownDetected:(NSString *)type;
-(void)apiResponseStatus:(int)code andData:(NSDictionary *)result;
-(void)unlinkuSccessful:(BOOL)isSuccess;
-(void)didReceiveSOSHistory:(NSMutableArray*)failSoslist;
-(void)glucometerData:(NSArray *)results;
@end

typedef void (^JWTTokenCompletionHandler)(NSDictionary * _Nullable response, NSError * _Nullable error);
typedef void (^DeviceLinkCompletionHandler)(NSDictionary * _Nullable response, NSError * _Nullable error);

#pragma mark - BLE Properties
@class Weather;
@class ContinuousHeartRate;
@class BPRange;
@interface BLE : NSObject<CBCentralManagerDelegate, CBPeripheralDelegate>{
    NSTimer *_readSomeDayDataTimer;
    NSTimer *_stopScanTimer;
    NSTimer *_stopSearchTimer;
    NSTimer *_stopConnectTimer;
    NSTimer *_stopUUIDScanTimer;
    BOOL _isCharacteristicsDiscoveryDone;
    BOOL isResposeRecived;
    CBPeripheral *_currentPeripheral;
    BLEDevice *_currentBLEDevice;
    BOOL isDone;
    int _bondStartTime;
    int callBackCount;
    BOOL isFoundSVDevice;
    NSMutableArray * hrvData;
    BOOL isECGReadingStart;
    int ecgSlotNo;
    NSString * ecgLastLogDateTimeSV2;
    NSString * ecgLogDateTimeSV2;
    NSArray *searchForDeviceList;
}
@property (readwrite) ProgressType progressType;
@property(nonatomic,assign)id delegate;
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral     *activePheriperal;
@property (nonatomic, strong) BLEDevice        *activeBLEDevice;
@property (nonatomic ,retain) CBCharacteristic *RxCharacteristic;
@property (nonatomic ,retain) CBCharacteristic *TxCharacteristic;

@property (nonatomic ,retain) NSString         *scanForDeviceName;
@property (nonatomic ,assign) BOOL         isDeviceConnected;
@property (nonatomic ,retain) NSMutableArray   *allpheriperals;
@property (nonatomic ,retain) NSDictionary *options;
@property (nonatomic, assign) int randomNo;
@property (nonatomic, retain) NSTimer *silenceTimer;


@property (nonatomic, assign) BOOL isSynchingProgress;
@property (nonatomic, assign) BOOL temp1Done;
@property (nonatomic, assign) BOOL temp2Done;
@property (nonatomic, assign) BOOL sleepDone;
@property (nonatomic, assign) BOOL stepsDone;
@property (nonatomic, assign) BOOL hr1Done;
@property (nonatomic, assign) BOOL hr2Done;
@property (nonatomic, assign) BOOL spo2Done;
@property (nonatomic, assign) BOOL activityDone;
@property (nonatomic, assign) BOOL bpDone;
@property (nonatomic, assign) BOOL ecgDone;
@property (nonatomic, assign) BOOL isLoginWithStagging;

#pragma mark - All Connection related Methods
-(void)cancelAllConnections;
+ (BLE *)sharedInstance;
-(void)startScan;
-(void)startScanWithTimeOut:(NSTimeInterval)timeout;
-(void)startScanUsingUUISStr:(NSString*)uuidStr;
-(void)stopScan;
-(void)stopAllDevicesScan;
-(void) stopConnectionTimer;
-(void)startConnectWithDevice:(CBPeripheral *)peripheral;
-(void)startConnectWithBLEDevice:(BLEDevice *)device;
-(BOOL)isBluetoothAvailable;

#pragma mark - GOQii Band Methods
- (void)getMacAddressFromGOQiiBand;
- (void)sendBondRequestToGOQiiBand;
- (void)sendBondRequestToGOQiiBandUsingMacAddress:(NSString *)mac_addr;
-(void) stopRealTimeDataForV3 : (int) start;
- (void)readRealTimeDataFromGOQiiBand;
- (void)readSomeDaydataFromGOQiiBand;
- (void)setPersonalInformationToGOQiiBand:(PersonalInfo *)info;
- (void)readPersonalInfoFromGOQiiBand;
- (void)setTargetToGOQiiBand:(NSString*)targetStr;
- (void)setTimeFormatToGOQiiBand:(NSString*)formatStr;
- (void)readTimeFormatFromGOQiiBand;
- (void)setDistanceFormatTOGOQiiBand:(NSString*)formatStr;
- (void)readDistanceFormatFromGOQiiBand;
- (void)readDeviceTimeFromGOQiiBand;
- (void)setGOQiiBandTimeToCurrentTime;
- (void)readBatteryFromGOQiiBand;
- (void)setDeviceOrientationToGOQiiBand:(NSString*)orientationStr;
- (void)readDeviceOrientationFromGOQiiBand;
- (void)readAlarmFromGOQiiBand:(int)alarmSlot;
- (void)setAlarmToGOQiiBand:(AlarmSet*)set;
- (void)readActiveTimeFromGOQiiBand;
-(void)setActiveTimeToGOQiiBand:(AlertDataSet*)set;
- (void)readFirmwareFromGOQiiBand;
-(void) readBPRange;
-(void) setBPRange:(BPRange *) bpRange;

// ECG Data
-(void)readECGData;
-(void)readECGData:(int) slotNo;
-(void)readECGDateTime:(int) slotNo;

-(void)readSleepStateFromGOQiiBand;
-(void)setSleepStateToGOQiiBand:(NSString *) stateStr;

- (void)readDailyDeviceDataFromGOQiiBand;

-(void)readNotificationStateFromGOQiiBand;
-(void)setNotificationStateToGOQiiBand:(NSString *)formatStr;

- (void)setRealTimeHeartRateMode:(NSString *)mode;
- (void)setHeartRateMeasuringMode:(NSString *)mode;
-(void)readRealtimeHeartRateModeFromGOQiiBand;
-(void)getSavedHRData;
-(void)setCustomNotificationOnTracker;
#pragma mark - Other Band Methods
-(BOOL)isV3Band;
-(void) setAlarmToGOQiiBeat:(NSArray *) alarmSet;
-(void)setAlarmToGOQiiBandV3:(AlarmSet*)set;
-(void)readAlarmFromGOQiiBandV3;
-(void)readNotificationAndDisplayStateFromGOQiiBandV3;
-(void)setNotificationAndDisplayStateToGOQiiBandV3:(BandDisplay *)band;
-(void)readDailyDeviceCumulativeDataFromGOQiiBandV3;
-(void)readDetailStepsDataFromV3WithDataID:(NSNumber*)dataId;
-(void)getDetailsSleepDataV3WithDataID:(NSNumber*)dataId;
-(void)getBloodPressureDataV3;
-(void)ReadDetailHeartRateData:(BOOL) isNextRecord;
-(void)ReadSingleManualHeartRateData:(BOOL) isNextRecord;
-(void)readExerciseModeData;
-(void)deleteBandDataWithMind:(int)mind;
-(void)deleteBandDataWithMind:(int)mind andDeleteCommand:(int) command;

#pragma mark -- Readr/Write - Weather Notification
-(void)setDisplayWeatherGOQiiBandV3:(Weather *)weather;

# pragma mark -- Read GPS
-(void)readGPSData:(NSNumber *)dataId;
-(void)readGPSPaceData:(NSNumber *)dataId;

# pragma mark -- read/ write continuous heart rate
-(void) setContinuouseHeartRate:(int)isEnable;
-(void) readContinuousHeartRate;

#pragma mark -- Readr/Write -Vital Connected GPS
-(void) sendDistanceTimeToVitalBand:(float) distance andTime:(int) time;
-(void) stopConnectGPSToVitalBand:(NSInteger) activityType;
-(void) startConnectGPSToVitalBand:(NSInteger) activityType;

-(void)enableSOS:(BOOL) enabled;

#pragma mark -- Readr/Write -Factory Reset
//-(void) factoryReset;

#pragma mark --- ECG start stop
-(void)realTimeHRVWithType:(int)type;
-(void)stopECGAndPPG;

#pragma mark --- Vital temperature read
-(void) getAllBodyTemperature:(NSNumber *) nextSlot;
-(void)readTemperatureData:(NSNumber *)dataId;
-(void)readTemperatureContinuousData:(NSNumber *)dataId;

#pragma mark --- GOQii Smart Vital
-(void)readSPO2Data:(NSNumber *)dataId;
-(void)startReadingSPO2Data:(BOOL) enable;
-(void)readHRVStressData:(NSNumber *)dataId;

#pragma mark -- write values
-(void)writeValue:(NSString*)serviceUUID characteristicUUID:(NSString*)characteristicUUID p:(CBPeripheral *)p data:(NSData *)data;
-(void)writeUIValue:(NSString*)serviceUUID characteristicUUID:(NSString*)characteristicUUID p:(CBPeripheral *)p data:(NSData *)data;
#pragma mark -- Set Wallpaper font
-(void) setWallpaperFont;
-(void)setCustomWatchFaceStyle:(int)watchFaceStyle;

#pragma mark -- Enable/Disable Women health
-(void) enableWomenHealth:(BOOL) enabled;
-(void) writeWomenHealthAlert:(int) phaseNo rDays:(int) remainingdays phaseStartMonth:(int) month phaseStartDay:(int) phaseDays;
-(void) writeWomenPregnancyAlert:(int) week weekDays:(int) weekDays startYear:(int) year startMonth:(int) month startDate:(int) date;
-(void) enableAndDisableSleepDisplayInTracker:(int)val;

#pragma mark -- Encryption and Decryption
-(NSString *)getEncryptedStringFor:(NSDictionary *)dataDic;
-(NSString *)getDecryptedStringFor:(NSString *)encryptedStr;

#pragma mark -- Tracker connect
-(void)scanTracker;
-(void)bondWithTracker:(CBPeripheral*)peripheral bleDevice:(BLEDevice *)device;
-(BOOL)isUUIDAvailable;
-(void)linkTrackerUsingUUID;
-(void)fetchUserInfoWithMobileNumber:(NSString *)mobile andEncryUserId:(NSString *)encryUserId andIsStagging:(BOOL)isStagging;
-(void)startTrackerSync;
-(void)unlinkTracker;
-(void)unlinkTrackerWithUserId:(NSString *)encUserId;
-(void)unlinkTrackerFromLocal;
-(void)sendMessage:(NSString *)msg andState:(BOOL)state;
-(void)uploadUserLocationForSOS: (NSString *)lat and:(NSString *)lon and:(NSString *)type and:(NSDictionary *)dataDict;
-(void)unlinkAPIDone:(BOOL)isSuccess;
-(void)readSOSHistory;
-(void)printSomeData;
-(void)navigateToWebView:(UIViewController *)vc;
-(BOOL)isTrakerSupport;
-(void)setupGlucometer:(UIViewController *)vc;
-(BOOL)isGlucoMeterConnected;
-(BOOL)unlinkGlucoMeter;
-(void)handleRedirectURI:(NSURL*)url;
-(void)navigateToFitbitConnect:(UIViewController *)vc;
-(void)navigateToGarminConnect:(UIViewController *)vc;
-(void)uploadGlucometerReadings:(NSArray *)results;
-(void)addMacForGlucometer:(NSString *)mac;
-(void)navigateToAppleHealth:(UIViewController *)vc;
-(void)navigateToAppsAndDevices:(UIViewController *)vc;
-(void)startAnimatingSearchingButton:(BOOL)flag andView:(UIView *) sender;
//-(void)setNetworkSetup:(NSString *)membershipNo;
//- (void)fetchGlucoseRecord:(NSString *)date
//               andForDepth:(NSString *)days
//                completion:(void (^)(NSDictionary *results, NSError *error))completion;

-(void)fetchDataGlucose:(NSString *)date AndDays:(NSString *)days;
-(NSString *)getGlucometerMac;
-(void)fetchJWTTokenWithEncData:(NSString *)encData completion:(JWTTokenCompletionHandler)completion;
@end
