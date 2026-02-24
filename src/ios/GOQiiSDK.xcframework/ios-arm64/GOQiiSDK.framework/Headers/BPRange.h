//
//  BPRange.h
//  bleSDKcreation
//
//  Created by Azim on 26/09/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BPRange : NSObject
@property                   int minDIA;// DIA min value 0-255
@property                   int maxDIA;// DIA min value 0-255
@property                   int minSYS;// SYS min value 0-255
@property                   int maxSYS;// SYS min value 0-255
@end

NS_ASSUME_NONNULL_END
