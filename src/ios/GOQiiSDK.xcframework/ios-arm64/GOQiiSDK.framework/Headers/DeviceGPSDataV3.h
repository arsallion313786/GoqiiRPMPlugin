//
//  DeviceGPSDataV3.h
//  GOQiiSDK
//
//  Created by Azim on 30/09/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DeviceGPSDataV3: NSObject
@property int l_gpsdataId;
@property (nonatomic, retain) NSString *logDate, *logDateTime,*lat,*lng,*elevation;
@end

NS_ASSUME_NONNULL_END
