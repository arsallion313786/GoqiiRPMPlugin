//
//  JSONParser.h
//  Goqii_DV
//
//  Created by Divum Corporate Services Pvt Ltd on 10/10/14.
//  Copyright (c) 2014 Divum. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface JSONParser : NSObject
+(id)postData:(NSString*)data usingURL:(NSString*)URLStr;
+(id)getAllTimeZones;
+(NSString *)getPayLoadStrToUpload:(NSArray *)array;
+(NSString *)getPayLoadStrToUploadWithDict:(NSDictionary *)dic;
+(NSString *)getPayLoadStrToUploadWithString:(NSString *)str;

+(NSString *)getNewPayLoadStrToUpload:(NSArray *)array;

@end
