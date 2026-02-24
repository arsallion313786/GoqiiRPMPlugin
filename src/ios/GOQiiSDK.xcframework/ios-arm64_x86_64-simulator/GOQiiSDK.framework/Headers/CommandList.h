//
//  CommandList.h
//  bleSDKcreation
//
//  Created by Azim on 26/09/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CommandList : NSObject
@property(nonatomic ,retain)NSString *commandName;
@property                   int commandIndex;
@property                   BOOL isLoopContinue;
@end

NS_ASSUME_NONNULL_END
