//
//  BLEDevice.h
//  bleSDKcreation
//
//  Created by Azim on 23/09/22.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN


typedef enum {
    NotConnected,
    Connected,
    Binded
    
}deviceState;


@interface BLEDevice : NSObject
@property (nonatomic ,retain) NSString *deviceName;
@property (nonatomic ,retain) NSString *macAddress;
@property (nonatomic ,retain) NSString *RSSI;
@property (nonatomic ,retain) CBPeripheral *peripheral;
@property (nonatomic ,retain) NSDictionary *advertisementData;
@property    (readwrite)      deviceState devicestate;
@end

NS_ASSUME_NONNULL_END
