//
//  YMSBFMConfiguration.m
//  Deanna
//
//  Created by Charles Choi on 1/24/17.
//  Copyright © 2017 Yummy Melon Software. All rights reserved.
//

#import "YMSBFMPeripheralConfiguration.h"

NSString *const kYMSBFMPeripheralConfigDefaultFilename = @"bfm.json";

NS_ASSUME_NONNULL_BEGIN

@interface YMSBFMPeripheralConfiguration ()

@property (nonatomic, strong) NSFileManager *fileManager;
@property (nonatomic, strong) NSDictionary<NSString *, NSArray<NSDictionary<NSString *, id> *> *> *configuration;

@end

@implementation YMSBFMPeripheralConfiguration

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
            configFileURL = [documentURL URLByAppendingPathComponent:kYMSBFMPeripheralConfigDefaultFilename];
        }
        
        if (configFileURL && [_fileManager fileExistsAtPath:configFileURL.path]) {
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

- (nullable instancetype)initWithConfigurationURL:(nullable NSURL *)url {
    self = [super init];
    if (self) {
        _fileManager = [NSFileManager defaultManager];
        
        if (!url) {
            NSArray<NSURL *> *a = [_fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
            
            NSURL *documentURL = nil;
            if (a.count >= 1) {
                documentURL = a[0];
                NSLog(@"Documents Folder: %@", documentURL);
            }

            url = [documentURL URLByAppendingPathComponent:kYMSBFMPeripheralConfigDefaultFilename];
        }
        
        if (url && [_fileManager fileExistsAtPath:url.path]) {
            NSData *jsonData = [NSData dataWithContentsOfURL:url];
            NSError *error = nil;
            _configuration = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:&error];
            
            if (error) {
                NSAssert(NO, @"ERROR: Processing JSON file %@ failed.", url);
            }
        } else {
            NSAssert(NO, @"ERROR: Configuration file %@ does not exist.", url);
        }
    }
    
    return self;
}


- (NSArray<NSDictionary<id, id> *> *)peripherals {
    NSArray<NSDictionary<id, id> *> *result = nil;
    
    result = _configuration[@"peripherals"];
    
    return result;
}

- (nullable NSDictionary<NSString *, id> *)peripheralWithName:(NSString *)className {
    NSDictionary<NSString *, id> *result = nil;
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"class_name == %@", className];
    NSArray<NSDictionary<id, id> *> *filteredPeripherals = [self.peripherals filteredArrayUsingPredicate:predicate];
    
    if (filteredPeripherals.firstObject) {
        result = filteredPeripherals.firstObject;
    }
    
    return result;
}

- (nullable NSDictionary<NSString *, NSDictionary<NSString *, id> *> *)servicesForPeripheral:(NSString *)className {
    NSDictionary<NSString *, NSDictionary<NSString *, id> *> *result = nil;

    NSDictionary<NSString *, id> *peripheral = [self peripheralWithName:className];
    
    if (peripheral) {
        result = peripheral[@"services"];
    }
    
    return result;
}

- (nullable NSDictionary<NSString *, NSDictionary<NSString *, id> *> *)characteristicsForServiceUUID:(NSString *)serviceUUID peripheral:(NSString *)peripheralClassName {
    NSDictionary<NSString *, NSDictionary<NSString *, id> *> *result = nil;
    
    NSDictionary<NSString *, NSDictionary<NSString *, id> *> *services = [self servicesForPeripheral:peripheralClassName];
    NSDictionary *service = services[serviceUUID];
    result = service[@"characteristics"];
    
    return result;
}

@end

NS_ASSUME_NONNULL_END
