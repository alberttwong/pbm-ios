//
//  AppDelegate.m
//  PinballMap
//
//  Created by Frank Michael on 4/12/14.
//  Copyright (c) 2014 Frank Michael Sanchez. All rights reserved.
//

#import "AppDelegate.h"
#import "PinballMapManager.h"
#import <HockeySDK/HockeySDK.h>
#import "LocationProfileView-iPad.h"
#import "GAI.h"
#import "ThirdPartyKeys.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    UIColor *pinkColor = [UIColor colorWithRed:1.0f green:0.0f blue:146.0f/255.0f alpha:1.0];
    [[UITabBar appearance] setTintColor:pinkColor];
    [[UISearchBar appearance] setTintColor:pinkColor];
    [[UINavigationBar appearance] setTintColor:pinkColor];
    [[UIToolbar appearance] setTintColor:pinkColor];
    [[UITableViewCell appearance] setTintColor:pinkColor];
    [[UITableView appearance] setTintColor:pinkColor];
    [[UISegmentedControl appearance] setTintColor:pinkColor];

    [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:[ThirdPartyKeys hockeyID]];
    [[BITHockeyManager sharedHockeyManager].authenticator setAuthenticationSecret:[ThirdPartyKeys hockeySecret]];
    [[BITHockeyManager sharedHockeyManager] startManager];
    [[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation];

    
    // Google Analytics
    // Optional: automatically send uncaught exceptions to Google Analytics.
    [GAI sharedInstance].trackUncaughtExceptions = YES;
    
    // Optional: set Google Analytics dispatch interval to e.g. 20 seconds.
    [GAI sharedInstance].dispatchInterval = 20;
    
    // Optional: set Logger to VERBOSE for debug information.
    [[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelVerbose];
    
    // Initialize tracker. Replace with your tracking ID.
    [[GAI sharedInstance] trackerWithTrackingId:[ThirdPartyKeys googleID]];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    if ([UIDevice iPad]){
        LocationProfileView_iPad *locations = (LocationProfileView_iPad *)[[[(UITabBarController *)self.window.rootViewController viewControllers] firstObject] navigationRootViewController];
        [locations showListingsView:nil];
    }

    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end