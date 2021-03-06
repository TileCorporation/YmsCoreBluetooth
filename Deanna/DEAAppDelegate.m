// 
// Copyright 2013-2015 Yummy Melon Software LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  Author: Charles Y. Choi <charles.choi@yummymelon.com>
//
//

#import "DEAAppDelegate.h"
#import "DEAPeripheralsViewController.h"
#import "DEACentralManager.h"
#import "DEATheme.h"
#import "DEAExternalCentral.h"
#import "YMSCBNativeInterfaces.h"
#import "YMSCBLogger.h"

@interface DEAAppDelegate() <YMSCBCentralManagerDelegate>
@property (nonatomic, strong) DEAExternalCentral *externalCentral;

@end


@implementation DEAAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self initializeUserDefaults];
    [self initializeAppServices];
    [self initializeAppearance];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [[DEATheme sharedTheme] backgroundColor];
    
    DEAPeripheralsViewController *pvc = [[DEAPeripheralsViewController alloc] initWithNibName:@"DEAPeripheralsViewController" bundle:nil];
    
    UINavigationController *nvc = [[UINavigationController alloc] initWithRootViewController:pvc];
    [DEATheme customizeNavigationController:nvc];

    self.window.rootViewController = nvc;
    
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)initializeUserDefaults {
}

- (void)initializeAppServices {
    _externalCentral = [[DEAExternalCentral alloc] init];
    DEACentralManager *tileSDK_Manager = [DEACentralManager initSharedServiceWithCentral:_externalCentral.central
                                                                                delegate:self
                                                                                   queue:nil
                                                                                 options:nil
                                                                                  logger:[YMSCBLogger new]];
    
    _externalCentral.delegate = tileSDK_Manager;
    
}

- (void)initializeAppearance {
    [DEATheme customizeApplication];
}

- (void)centralManagerDidUpdateState:(YMSCBCentralManager *)yCentral {
    
    _YMS_PERFORM_ON_MAIN_THREAD(^{
        switch (yCentral.state) {
            case CBCentralManagerStatePoweredOn:
                break;
            case CBCentralManagerStatePoweredOff:
                break;
                
            case CBCentralManagerStateUnsupported: {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Dang."
                                                                message:@"Unfortunately this device can not talk to Bluetooth Smart (Low Energy) Devices"
                                                               delegate:nil
                                                      cancelButtonTitle:@"Dismiss"
                                                      otherButtonTitles:nil];
                
                [alert show];
                break;
            }
                
                
            default:
                break;
        }
    });

}

@end
