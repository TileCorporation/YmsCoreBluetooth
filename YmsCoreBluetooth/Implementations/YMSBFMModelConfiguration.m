//
//  YMSBFMModelConfiguration.m
//  Deanna
//
//  Created by Paul Wong on 1/26/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

#import "YMSBFMModelConfiguration.h"

NSString *const kYMSBFMModelConfigDefaultFilename = @"model.json";

NS_ASSUME_NONNULL_BEGIN

@interface YMSBFMModelConfiguration ()

@property (nonatomic, strong) NSFileManager *fileManager;
@property (nonatomic, strong) NSDictionary<NSString *, NSDictionary<NSString *, id> *> *configuration;

@end

@implementation YMSBFMModelConfiguration

- (nullable instancetype)initWithConfigurationFile:(nullable NSString *)filename {
    self = [super init];
    if (self) {
        
        _fileManager = [NSFileManager defaultManager];
        
        [_fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
        
        NSArray<NSURL *> *a = [_fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
        
        NSURL *documentURL = nil;
        if (a.count >= 1) {
            documentURL = a[0];
            NSLog(@"Documents Folder: %@", documentURL);
        }
        
        NSURL *configFileURL = nil;
        
        if (filename) {
            configFileURL = [documentURL URLByAppendingPathComponent:filename];
        } else {
            configFileURL = [documentURL URLByAppendingPathComponent:kYMSBFMModelConfigDefaultFilename];
        }
        
        if ([_fileManager fileExistsAtPath:configFileURL.path]) {
            NSData *jsonData = [NSData dataWithContentsOfURL:configFileURL];
            NSError *error = nil;
            _configuration = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:&error];
            
            if (error) {
                NSAssert(NO, @"ERROR: Processing JSON file %@ failed.", configFileURL);
            }
        } else {
            NSAssert(NO, @"ERROR: Configuration file %@ does not exist.", configFileURL);
        }
        
        
    }
    return self;
}

- (nullable NSDictionary<NSString *, NSDictionary<NSString *, id> *> *)peripherals {
    NSDictionary<NSString *, NSDictionary<NSString *, id> *> *result = nil;
    result = [NSDictionary dictionaryWithDictionary:_configuration[@"peripherals"]];
    return result;
}

- (nullable NSDictionary<NSString *, NSDictionary<NSString *, id> *> *)servicesForPeripheralIdentifier:(NSString *)identifier {
    NSDictionary<NSString *, NSDictionary<NSString *, id> *> *peripherals = [self peripherals];
    NSDictionary<NSString *, NSDictionary<NSString *, id> *> *result = nil;
    result = peripherals[identifier][@"services"];
    return result;
}

- (nullable NSDictionary<NSString *, NSDictionary<NSString *, id> *> *)characteristicForService:(NSDictionary<NSString *, NSDictionary<NSString *, id> *> *)service withCharacteristicUUID:(NSString *)uuid {
    NSDictionary<NSString *, NSDictionary<NSString *, id> *> *result = nil;
    result = service[uuid];
    return result;
}

@end

NS_ASSUME_NONNULL_END
