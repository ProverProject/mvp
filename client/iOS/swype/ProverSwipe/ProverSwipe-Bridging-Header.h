//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//
#include <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonKeyDerivation.h>


#import "Crypto.h"
#import "NSData+Base64.h"

#import "SwypeDetectorCppWrapper.h"

void createPrivateKey(unsigned char *out_private_key);
void createPublicKey(unsigned char *public_key, unsigned char *private_key);

void ed25519_key_exchange_nem(unsigned char *shared_secret, const unsigned char *public_key, const unsigned char *private_key, const unsigned char *salt);

void SHA256_hash(unsigned char *out,unsigned char *in , int32_t inLen);

void ed25519_sign(unsigned char *signature, const unsigned char *message, int32_t message_len, const unsigned char *public_key, const unsigned char *private_key);
void ed25519_key_exchange_nem_test();

void Sign(unsigned char *signature, unsigned char *data, int32_t dataSize, unsigned char *public_key ,unsigned char *privateKey);
