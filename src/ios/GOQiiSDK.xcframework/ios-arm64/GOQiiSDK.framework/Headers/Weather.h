//
//  Weather.h
//  bleSDKcreation
//
//  Created by Azim on 26/09/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Weather : NSObject
@property(nonatomic ,retain)NSString *city;
@property(nonatomic ,retain)NSString *date;
@property                   int weatherCondition;
@property                   int weatherType;
@property                   int temperature;
@property                   int minTemp;
@property                   int maxTemp;
@end

NS_ASSUME_NONNULL_END
