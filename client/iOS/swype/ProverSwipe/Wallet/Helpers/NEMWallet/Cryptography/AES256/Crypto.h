#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonHMAC.h>

@interface Crypto : NSObject

- (NSString*) sha256HashFor:(NSString*)input;

@end

@interface NSData (AESAdditions)
- (NSData*) AES256EncryptWithKey:(NSString*)key iv:(NSString *)iv;
- (NSData*) AES256DecryptWithKey:(NSString*)key iv:(NSString *)iv;
- (NSData *)generateRandomIV:(size_t)length;
- (NSString*) sha256:(NSString *)key length:(NSInteger) length;

@end