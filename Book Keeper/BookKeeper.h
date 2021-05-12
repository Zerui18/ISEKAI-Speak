//
//  BookKeeper.h
//  Book Keeper
//
//  Created by Zerui Chen on 9/4/21.
//

#ifndef BookKeeper_h
#define BookKeeper_h

#include <stdio.h>
#include <Foundation/Foundation.h>

@interface BookKeeper: NSObject {
    bool isDuringInit;
    void *binaryAddress;
    NSArray<NSValue *> *voiceAddresses;
    NSArray<NSValue *> *dictAddresses;
}

@property(nonatomic, setter=setVoice:) NSInteger voice;
@property(nonatomic, setter=setLanguage:) NSInteger language;

- (id _Nonnull) initWithResourcesPath: (NSString * _Nonnull) resourcesPath;

- (NSData * _Nonnull) generatePCMWithText: (NSString * _Nonnull) text;

- (bool) generateWavWithText: (NSString * _Nonnull)text atPath: (NSString * _Nonnull)path;

@end

#endif /* BookKeeper_h */
