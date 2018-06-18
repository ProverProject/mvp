#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <time.h>

#include "src/ed25519.h"
#include "src/ge.h"
#include "src/sc.h"

#include "sha3.h"

const size_t privateKeyPartSize = 32;
const size_t signaturePartRAM = 32;
const size_t privateKeySize = 64;
const size_t publicKeySize = 32;
const size_t signatureSize = 64;
const size_t seedSize = 32;
const size_t hash_512_Size = 64;
const size_t hash_256_Size = 32;

void toHex(unsigned char *outHex, unsigned  char *inBytes, int32_t inBytesLen )
{
    const char szNibbleToHex[] = {"0123456789abcdef" };
    
    for (int i = 0; i < inBytesLen; i++) {
        int nNibble = inBytes[i] >> 4;
        outHex[2 * i]  = szNibbleToHex[nNibble];
        
        nNibble = inBytes[i] & 0x0F;
        outHex[2 * i + 1]  = szNibbleToHex[nNibble];
        
    }
}

void SHA256_hash(unsigned char *out,unsigned  char *in , int32_t inLen )
{
    uint8_t md[hash_256_Size];

    sha3_256(in, inLen, md);

    toHex(out, &md, hash_256_Size);

}

void createPrivateKey(unsigned char *out_private_key)
{
    unsigned char  private_key[privateKeySize], seed[seedSize];
    
    ed25519_create_seed(seed);
    
    sha3_512(seed, seedSize, private_key);
    
    for (int i = 0; i < privateKeyPartSize; i++) {
        out_private_key[i] = private_key[i];
    }
}

void createPublicKey(unsigned char *public_key,  unsigned char *private_key)
{   

    unsigned char private_key_hash[privateKeySize];
    
    sha3_512(private_key, privateKeyPartSize, private_key_hash);
    
    private_key_hash[0] &= 248;
    private_key_hash[31] &= 127;
    private_key_hash[31] |= 64;
    
    ge_p3 A;
    unsigned char public_key_buffer [publicKeySize];
    
    ge_scalarmult_base(&A, private_key_hash);
    
    ge_p3_tobytes(public_key_buffer, &A);
    
    for(int i=0;i < publicKeySize ;i++) {
        public_key[i] = public_key_buffer[i];
    }
    
}

void Sign(unsigned char *signature, unsigned char *data, int32_t dataSize, unsigned char *public_key ,unsigned char *privateKey)
{
    unsigned char hram[64];
    unsigned char r[64];
    unsigned char *inData;
    unsigned char privateKeyHash[hash_512_Size];
    unsigned char private_key_bytes[privateKeyPartSize];
    unsigned char public_key_bytes[publicKeySize];
    
    ge_p3 R;
    
    for (int i=0 ;i < privateKeyPartSize;++i) {
        int value;
        sscanf(privateKey + 2 * i,"%02x",&value);
        private_key_bytes[privateKeyPartSize - 1 - i ] = value;
    }
    
    sha3_512(private_key_bytes, privateKeyPartSize, privateKeyHash);
    
    inData = (unsigned char*) malloc(dataSize + privateKeyPartSize);
    
    memcpy(inData, privateKeyHash + privateKeyPartSize, privateKeyPartSize);
    memcpy(inData + privateKeyPartSize, data, dataSize);
    
    sha3_512(inData, dataSize + privateKeyPartSize, r);
    
    free(inData);
    
    sc_reduce(r);
    ge_scalarmult_base(&R, r);
    ge_p3_tobytes(signature, &R);
    
    for (int i = 0 ;i < publicKeySize;++i) {
        int value;
        sscanf(public_key + 2 * i,"%02x",&value);
        private_key_bytes[i] = value;
    }
    
    inData = (unsigned char*) malloc(dataSize + publicKeySize + signaturePartRAM);
    
    memcpy(inData, signature, signaturePartRAM);
    memcpy(inData + signaturePartRAM, private_key_bytes, publicKeySize);
    memcpy(inData + signaturePartRAM + publicKeySize, data, dataSize);
    
    sha3_512(inData, dataSize + signaturePartRAM + publicKeySize, hram);
    
    free(inData);
    
    unsigned char *privateKeyRightPart = (unsigned char*) malloc(privateKeyPartSize);
    
    memcpy(privateKeyRightPart, privateKeyHash, privateKeyPartSize);
    
    privateKeyRightPart[0] &= 248;
    privateKeyRightPart[31] &= 127;
    privateKeyRightPart[31] |= 64;
    
    sc_reduce(hram);
    sc_muladd(signature + signaturePartRAM, hram, privateKeyRightPart, r);
    
    free(privateKeyRightPart);
}

void negate(ge_p3 *A) {
    fe_neg(A->X, A->X);
    fe_neg(A->T, A->T);
}

void ed25519_key_exchange_nem(unsigned char *shared_secret, const unsigned char *public_key, const unsigned char *private_key, const unsigned char *salt) {
    ge_p3 A;
    ge_p2 R;
    unsigned char r[32];
    unsigned char e[32];
    unsigned char zero[32];
    unsigned int i;
    
    unsigned char private_key_hash[privateKeySize];
    
    sha3_512(private_key, privateKeyPartSize, private_key_hash);
    
    private_key_hash[0] &= 248;
    private_key_hash[31] &= 127;
    private_key_hash[31] |= 64;
    
    /* initialize zero and shared secret */
    for (i = 0; i < 32; ++i) {
        zero[i] = 0;
        shared_secret[i] = 0;
    }
    
    /* decode group element */
    if (ge_frombytes_negate_vartime(&A, public_key) != 0) {
        return;
    }
    
    /* need to negate A again */
    negate(&A);
    
    /* copy the private key and make sure it's valid */
    for (i = 0; i < 32; ++i) {
        e[i] = private_key_hash[i];
    }
    
    e[0] &= 248;
    e[31] &= 63;
    e[31] |= 64;
    
    /* R = e * A + 0 * B */
    ge_double_scalarmult_vartime(&R, e, &A, zero);
    
    /* encode group element */
    ge_tobytes(r, &R);
    
    /* apply salt */
    for (i = 0; i < 32; ++i) {
        r[i] ^= salt[i];
    }
    
    /* hash the result */
    sha3_256(r, privateKeyPartSize, shared_secret);
}

const static uint8_t privateKey1[32] = {
    0xc0, 0x01, 0x12, 0xd3, 0x4d, 0x19, 0x26, 0xb3,
    0x72, 0x41, 0xc6, 0xb2, 0x17, 0x7f, 0x1b, 0x53,
    0xd7, 0x75, 0x33, 0xa1, 0x5c, 0xc2, 0xf9, 0x55,
    0x2d, 0xa4, 0xdb, 0x5e, 0xc7, 0x72, 0x1f, 0x43
};

const static uint8_t publicKey1[32] = {
    0x1e, 0xde, 0xec, 0xfb, 0x30, 0x17, 0xca, 0x78,
    0xaf, 0xa5, 0x13, 0x4d, 0xcb, 0x9f, 0x34, 0xf0,
    0x10, 0x42, 0xea, 0xf6, 0xe9, 0xe7, 0x23, 0xd5,
    0xd0, 0x8a, 0x78, 0xc8, 0xaf, 0xac, 0x6a, 0x95
};

const static uint8_t salt1[32] = {
    0xb0, 0xca, 0x42, 0x06, 0x0e, 0x14, 0x0a, 0xfd,
    0xf8, 0x90, 0x6b, 0x63, 0xd0, 0x5d, 0xed, 0x47,
    0x13, 0xed, 0x41, 0xe6, 0x48, 0x83, 0xd1, 0xf2,
    0x19, 0xe8, 0xe9, 0x9e, 0x2b, 0xd7, 0x1d, 0xba
};

const static uint8_t expected_shared_secret1[32] = {
    0x5d, 0xd2, 0x59, 0xdb, 0xc9, 0x6b, 0x14, 0x18,
    0x46, 0xce, 0xd2, 0x52, 0x3e, 0xd2, 0x07, 0x07,
    0x48, 0x4f, 0x2c, 0x6a, 0xa5, 0xfe, 0x06, 0x2a,
    0xcc, 0x76, 0x9d, 0xc1, 0xb7, 0xfa, 0x02, 0x30
};

/* data for shared secret test 2 */
const static uint8_t privateKey2[32] = {
    0x68, 0x85, 0x5b, 0xb7, 0x1d, 0x3f, 0x7a, 0xd7,
    0xd6, 0x0d, 0xea, 0xf4, 0x5c, 0x63, 0x00, 0xa0,
    0xad, 0xee, 0xee, 0x3a, 0x3d, 0xe6, 0x60, 0x07,
    0x14, 0x12, 0xe4, 0xba, 0x9d, 0x62, 0x99, 0x44
};

const static uint8_t publicKey2[32] = {
    0x01, 0x5b, 0x27, 0x3c, 0xae, 0x61, 0x55, 0x47,
    0x8e, 0x5e, 0x56, 0xff, 0x64, 0xbd, 0xa2, 0xa3,
    0x02, 0x50, 0xf0, 0xf3, 0x75, 0x2e, 0x06, 0x3f,
    0x8d, 0xa9, 0x15, 0x70, 0x77, 0xb3, 0x2d, 0x6a
};

const static uint8_t salt2[32] = {
    0x54, 0xe5, 0x26, 0x40, 0xdc, 0xeb, 0x23, 0x85,
    0x7a, 0x4f, 0xdb, 0xa4, 0x5d, 0x81, 0x48, 0x47,
    0xe7, 0xcb, 0x49, 0x61, 0x8e, 0xb6, 0x96, 0x16,
    0xb9, 0xd4, 0x6e, 0x68, 0xf6, 0x1d, 0xad, 0x4c
};

const static uint8_t expected_shared_secret2[32] = {
    0x27, 0xae, 0x9c, 0xf4, 0xb1, 0xc0, 0xf9, 0x24,
    0x68, 0xa9, 0xe4, 0x29, 0xaa, 0xf8, 0xd3, 0x24,
    0x14, 0xd3, 0x78, 0x3b, 0x3a, 0x5b, 0x4d, 0x17,
    0x44, 0x42, 0x1e, 0xf2, 0xaa, 0x17, 0x82, 0xed
};

void check_for_difference(uint8_t *shared_secret, const uint8_t *expected_shared_secret) {
    uint8_t i;
    for (i = 0; i < 32; i++) {
        if (shared_secret[i] != expected_shared_secret[i]) {
            printf("difference in shared secrets found at position %d: expected %d, found %d.\n", i, expected_shared_secret[i], shared_secret[i]);
            return;
        }
    }
    
    printf("shared secret is as expected.\n");
}

void ed25519_key_exchange_nem_test() {
    uint8_t shared_secret[32];
    
    ed25519_key_exchange_nem(shared_secret, publicKey1, privateKey1, salt1);
    check_for_difference(shared_secret, expected_shared_secret1);
    ed25519_key_exchange_nem(shared_secret, publicKey2, privateKey2, salt2);
    check_for_difference(shared_secret, expected_shared_secret2);
}

