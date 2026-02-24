//
//  NSData+Encrypt.h
//  GOQiiNative
//
//  Created by GOQii-Roshan on 01/12/22.
//  Copyright © 2022 GOQii. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCryptor.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (Encrypt)

- (NSData *)AES256GOQiiEncryptWithKey:(NSString *)key andWithIV:(NSString*)iv;

- (NSData *)AES256GOQiiDecryptWithKey:(NSString *)key andWithIV:(NSString*)iv;
@end

NS_ASSUME_NONNULL_END
