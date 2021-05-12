//
//  test.c
//  Book Keeper
//
//  Created by Zerui Chen on 9/4/21.
//

#include "test.h"

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
#include <Foundation/Foundation.h>
#include <signal.h>

void* ADDRESS = (void*)0x300000000;
void *addr;

NSMutableData *generatedData;
void onGeneratedBytes(const unsigned char* bytes, size_t length) {
    [generatedData appendBytes:bytes length:length];
}

unsigned char GeneratedData[16 * 1024 * 1024];
size_t curr = 0;

int test(const char* BINARY_PATH, const char* VOICE_PATH, const char* DICT_PATH)
{
    // Programs
    addr = mmap((void *) 0x300000000, 128LL * 1024 * 1024, PROT_NONE, MAP_PRIVATE | MAP_ANON, -1, 0);

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

    // Data
    int fdvd = open(VOICE_PATH, O_RDONLY);
    if (fdvd == -1)
    {
        perror("open voice_data");
        exit(1);
    }


    void* voice_data = mmap(NULL, 128LL * 1024 * 1024, PROT_READ, MAP_SHARED, fdvd, 0);
    if (voice_data == (void*)-1)
    {
        perror("mmap voice_data");
        exit(1);
    }

    int fdld = open(DICT_PATH, O_RDONLY);
    if (fdld == -1)
    {
        perror("open lang_dict");
        exit(1);
    }


    void* dict_data = mmap(NULL, 16LL * 1024 * 1024, PROT_READ, MAP_SHARED, fdld, 0);
    if (dict_data == (void*)-1)
    {
        perror("mmap lang_dict");
        exit(1);
    }


    // Load Program
    FILE* f = fopen(BINARY_PATH, "rb");
    if (f == NULL)
    {
        perror("fopen program");
        raise(sig)
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

    // Data Addr
    memcpy(addr + 0x286CA70, &voice_data, 8);
    memcpy(addr + 0x286CA78, &dict_data, 8);

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
    void* generated_ptr = onGeneratedBytes;
    memcpy(addr + 0x23DDA68, &generated_ptr, 8);

    // Return when done
    memcpy(addr + 0x346B38, "\x1A\x00\x00\x14", 4);

    mprotect(addr, 0x1F00000, PROT_EXEC);

    // Cache flush
    sys_icache_invalidate(addr, s);

    // init
    ((long long(*)(void *))(addr + 0x346738))(addr + 0x286CA80);

    // init user lex
    ((long long(*)(void))(addr + 0x340F78))();
    
    return 0;
}

void generate() {
    const char* text = "おはようございます";
    
    // generate
    ((long long(*)(void*, const char*, char))(addr + 0x3469D8))(NULL, text, 1);
    
    printf("generated bytes: %d\n", curr);
}
