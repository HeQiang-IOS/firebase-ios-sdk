/*
 * Copyright 2019 Google
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <mach-o/fat.h>
#import <mach-o/loader.h>
#import "FIRAppDistributionMachO.h"
#import "FIRAppDistributionMachOSlice.h"

@implementation FIRAppDistributionMachO

- (instancetype)initWithPath:(NSString *)path {
    self = [super init];
    
    if (self) {
        _path = path;
        _slices = [NSMutableArray new];
    }
    
    [self extractSlices];
    
    return self;
}

- (void)extractSlices {
    NSData *data;
    uint32_t magicValue;
    NSFileHandle *fh = [NSFileHandle fileHandleForReadingAtPath:_path];
    
    struct fat_header fheader;
    data = [fh readDataOfLength:sizeof(fheader)];
    [data getBytes:&fheader length:sizeof(fheader)];
   
    magicValue = CFSwapInt32HostToBig(fheader.magic);
    
    if (magicValue == FAT_MAGIC || magicValue == FAT_CIGAM) {
        uint32_t archCount = CFSwapInt32HostToBig(fheader.nfat_arch);
        
        for (uint32_t i = 0; i < archCount; i++) {
            struct mach_header* mheader;
            
            data = [fh readDataOfLength:sizeof(mheader)];
            [data getBytes:&mheader length:sizeof(mheader)];
        }
    } else {
        [fh seekToFileOffset:0];
        struct mach_header mheader;
        
        data = [fh readDataOfLength:sizeof(mheader)];
        [data getBytes:&mheader length:sizeof(mheader)];
        magicValue = CFSwapInt32HostToBig(mheader.magic);

        // If binary is 64-bit, read reserved bit and discard it
        if (magicValue == MH_CIGAM_64) {
            uint32_t reserved;

            [fh readDataOfLength:sizeof(reserved)];
        }
    }
}

- (NSString*)instanceIdentifier {
    return @"";
}

@end
