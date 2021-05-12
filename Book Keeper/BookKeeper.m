//
//  BookKeeper.c
//  Book Keeper
//
//  Created by Zerui Chen on 9/4/21.
//

#include "BookKeeper.h"

#include <stdio.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <libkern/OSCacheControl.h>
#include <pthread/pthread.h>
#include <stdbool.h>
#include <math.h>

static NSMutableData *generatedData;
static void onGeneratedBytes(const unsigned char* bytes, size_t length) {
    [generatedData appendBytes:bytes length:length];
}

@implementation BookKeeper

- (id) initWithResourcesPath: (NSString *) resourcesPath {
    self = [super init];
    self->isDuringInit = true;
    #if TARGET_OS_IOS && !TARGET_IPHONE_SIMULATOR
    [self loadVoicesAndDicts: resourcesPath];
    [self loadAndPatchBinary: resourcesPath];
    #endif
    self->isDuringInit = false;
    return self;
}

- (void) setVoice: (NSInteger)voice {
    self->_voice = voice;
    void *voiceAddress = self->voiceAddresses[voice].pointerValue;
    memcpy(self->binaryAddress + 0x286CA70, &voiceAddress, 8);
    
    if (!isDuringInit) {
        // init
        ((long long(*)(void *))(self->binaryAddress + 0x346738))(self->binaryAddress + 0x286CA80);

        // init user lex
        ((long long(*)(void))(self->binaryAddress + 0x340F78))();
    }
}

- (void) setLanguage: (NSInteger)language {
    self->_language = language;
    void *dictAddress = self->dictAddresses[language].pointerValue;
    memcpy(self->binaryAddress + 0x286CA78, &dictAddress, 8);
    
    if (!isDuringInit) {
        // init
        ((long long(*)(void *))(self->binaryAddress + 0x346738))(self->binaryAddress + 0x286CA80);

        // init user lex
        ((long long(*)(void))(self->binaryAddress + 0x340F78))();
    }
}

- (void) loadVoicesAndDicts: (NSString *) resourcesPath {
    
    // Load Voice Data Files.
    NSArray<NSString *> *voiceNames = @[@"c001_ttsdata_megumin.voiceL", @"c002_ttsdata_raphtalia.voiceL"];
    NSMutableArray<NSValue *> *voiceAddresses = [NSMutableArray array];
    for (id voiceName in voiceNames) {
        int fdvd = open([resourcesPath stringByAppendingPathComponent:voiceName].UTF8String, O_RDONLY);
        if (fdvd == -1)
        {
            perror("open voice_data");
            exit(1);
        }
        
        void* voice_data = mmap(0, 128LL * 1024 * 1024, PROT_READ, MAP_SHARED, fdvd, 0);
        if (voice_data == (void*)-1)
        {
            perror("mmap voice_data");
            exit(1);
        }
        
        [voiceAddresses addObject: [NSValue valueWithPointer: voice_data]];
        
        close(fdvd);
    }
    self->voiceAddresses = voiceAddresses;
    
    // Load Language Dictionaries.
    NSArray<NSString *> *dictNames = @[@"jaJP_langDicGx_n40c_R2.dicL"];
    NSMutableArray<NSValue *> *dictAddresses = [NSMutableArray array];
    for (id dictName in dictNames) {
        int fdvd = open([resourcesPath stringByAppendingPathComponent:dictName].UTF8String, O_RDONLY);
        if (fdvd == -1)
        {
            perror("open voice_data");
            exit(1);
        }
        
        void* dict_data = mmap(0, 16LL * 1024 * 1024, PROT_READ, MAP_SHARED, fdvd, 0);
        if (dict_data == (void*)-1)
        {
            perror("mmap dict_data");
            exit(1);
        }
        
        [dictAddresses addObject: [NSValue valueWithPointer: dict_data]];
        
        close(fdvd);
    }
    self->dictAddresses = dictAddresses;
}

- (void) loadAndPatchBinary: (NSString *) resourcesPath {
    
    // Program
    void* addr = mmap((void *) 0x300000000, 128LL * 1024 * 1024, PROT_NONE, MAP_PRIVATE | MAP_ANON, -1, 0);
    self->binaryAddress = addr;

    if (addr == (void*)-1)
    {
        perror("mmap program");
        exit(1);
    }
    printf("%p\n", addr);

    // Set Permission
    int ret = mprotect(addr, 0x1F00000, PROT_WRITE);
    if (ret == -1)
    {
        perror("mark code W");
        exit(1);
    }

    ret = mprotect(addr + 0x1F00000, 128LL * 1024 * 1024 - 0x1F00000, PROT_WRITE);
    if (ret == -1)
    {
        perror("mark data W");
        exit(1);
    }

    // Load Program
    FILE* f = fopen([resourcesPath stringByAppendingPathComponent:@"bookwalker"].UTF8String, "rb");
    if (f == NULL)
    {
        perror("fopen program");
        raise(SIGTRAP);
    }
    fseek(f, 0, SEEK_END);
    size_t s = ftell(f);
    rewind(f);

    // Write into memory
    unsigned char buffer[1024];
    for (int i = 0; i != s / 1024; i++)
    {
        fread(buffer, sizeof(unsigned char), 1024, f);
        memcpy(addr + i * 1024, buffer, 1024);
    }
    fread(buffer, sizeof(unsigned char), s % 1024, f);
    memcpy(addr + s - s % 1024, buffer, s % 1024);

    // Stack guard fix
    const char* stack_guard = "\x32\x54\x31\x20\x19\x17\x0a\x5d";
    memcpy(addr + 0x23DC570, &stack_guard, 8);

    // Import functions fix
    void* calloc_ptr = calloc;
    memcpy(addr + 0x23DD350, &calloc_ptr, 8);
    void* malloc_ptr = malloc;
    memcpy(addr + 0x23DD8F0, &malloc_ptr, 8);
    void* printf_ptr = printf;
    memcpy(addr + 0x23DDB58, &printf_ptr, 8);
    void* memset_ptr = memset;
    memcpy(addr + 0x23DD920, &memset_ptr, 8);
    void* bzero_ptr = bzero;
    memcpy(addr + 0x23DD348, &bzero_ptr, 8);
    void* cos_ptr = cos;
    memcpy(addr + 0x23DD3F0, &cos_ptr, 8);
    void* puts_ptr = puts;
    memcpy(addr + 0x23DDCC8, &puts_ptr, 8);
    void* log_ptr = log;
    memcpy(addr + 0x23DD840, &log_ptr, 8);
    void* pow_ptr = pow;
    memcpy(addr + 0x23DDB48, &pow_ptr, 8);
    void* exp_ptr = exp;
    memcpy(addr + 0x23DD560, &exp_ptr, 8);
    void* memset_pattern16_ptr = memset_pattern16;
    memcpy(addr + 0x23DD928, &memset_pattern16_ptr, 8);
    
    [self setVoice: 0];
    [self setLanguage: 0];

    // Abs Addr Fix
    for(size_t i = 0x23DF020; i <= 0x26662B8; i += 0x8)
    {
        if(*((unsigned long long*)(addr + i)) >= 0x100000000 && *((unsigned long long*)(addr + i)) <= 0x110000000)
        {
            *((unsigned long long*)(addr + i)) += (unsigned long long)addr - 0x100000000;
        }
    }
    
    // Skip code
    memcpy(addr + 0x34676C, "\x38\x29\x01\xD0\x37\x29\x01\xD0\x26\x00\x00\x14", 12);
    memcpy(addr + 0x346848, "\x04\x00\x00\x14", 4);
    memcpy(addr + 0x346A18, "\x20\x00\x00\x14", 4);

    // Store result
    memcpy(addr + 0x346B1C, "\xe1\x0b\x40\xf9\xe0\x63\x00\x91\x1f\x20\x03\xd5\x1f\x20\x03\xd5", 16);
    void *callback = onGeneratedBytes;
    memcpy(addr + 0x23DDA68, &callback, 8);

    // Return when done
    memcpy(addr + 0x346B38, "\x1A\x00\x00\x14", 4);

    mprotect(addr, 0x1F00000, PROT_EXEC);

    // Cache flush
    sys_icache_invalidate(addr, s);
    
    // init
    ((long long(*)(void *))(addr + 0x346738))(addr + 0x286CA80);

    // init user lex
    ((long long(*)(void))(addr + 0x340F78))();
}

- (NSData *) generatePCMWithText: (NSString *)text {
    #if TARGET_OS_IOS && !TARGET_IPHONE_SIMULATOR
    generatedData = [[NSMutableData alloc] init];
    long long (*generateFunc)(void*, const char*, char) = self->binaryAddress + 0x3469D8;
    generateFunc(NULL, [text cStringUsingEncoding: NSUTF8StringEncoding], 1);
    return generatedData;
    #else
    return [NSData alloc];
    #endif
}

- (bool) generateWavWithText: (NSString *)text atPath: (NSString *)path {
    NSData *pcm = [self generatePCMWithText:text];
    FILE* output = fopen(path.UTF8String, "wb");
    if (output == NULL)
    {
        perror("fopen");
        return false;
    }
    fwrite("RIFF", sizeof(unsigned char), 4, output);
    unsigned int data = (unsigned int)pcm.length + 36;
    fwrite(&data, sizeof(unsigned char), 4, output);
    fwrite("WAVE", sizeof(unsigned char), 4, output);
    fwrite("fmt ", sizeof(unsigned char), 4, output);
    data = 16;
    fwrite(&data, sizeof(unsigned char), 4, output);
    data = 1;
    fwrite(&data, sizeof(unsigned char), 2, output);
    fwrite(&data, sizeof(unsigned char), 2, output);
    data = 44100;
    fwrite(&data, sizeof(unsigned char), 4, output);
    data = 88200;
    fwrite(&data, sizeof(unsigned char), 4, output);
    data = 2;
    fwrite(&data, sizeof(unsigned char), 2, output);
    data = 16;
    fwrite(&data, sizeof(unsigned char), 2, output);
    fwrite("data", sizeof(unsigned char), 4, output);
    data = (unsigned int)pcm.length;
    fwrite(&data, sizeof(unsigned char), 4, output);
    fwrite(pcm.bytes, sizeof(unsigned char), pcm.length, output);
    fclose(output);
    
    return true;
}

@end
