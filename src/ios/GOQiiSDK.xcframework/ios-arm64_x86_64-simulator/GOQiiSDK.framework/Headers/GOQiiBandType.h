//
//  GOQiiBandType.h
//  bleSDKcreation
//
//  Created by Azim on 23/09/22.
//
//

#import <Foundation/Foundation.h>
#import "BandConstants.h"

@interface GOQiiBandType : NSObject
{
    CoreType coreType;
    int bandStatus;
}

+ (GOQiiBandType *)sharedInstance;

-(void)setCoreTypeFromVersion:(int) firmwareVersion;
-(void)setCoreTypeFromName:(NSString *) bandName;

-(NSString *) getFirmwareString;
-(int) getFirmwareIntValue;
-(int)getFirmwareVersionFirstValue;

-(void) setCoreType:(CoreType) core;
-(CoreType)getCoreType;
-(NSString *)getCoreName;
-(NSString *)setCoreNameFromVersion;
-(NSString *)setBLEDeviceNameFromVersion;
-(NSString *) getCoreImage ;
-(void)setBandStatus:(int)status;
-(int)getBandStatus;
-(BOOL)isBandTypeSV;
-(BOOL)isWomenHealthCareOptionEnable;
-(BOOL)isBloodPressureOptionAvilable;
@end
