//
//  AppDelegate.m
//  CoreTextDemo
//
//  Created by Bingo on 2018/7/9.
//  Copyright © 2018年 Bingo. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.window makeKeyAndVisible];
    Class cls = NSClassFromString(@"HomeTableViewController");
    if (!cls) {
        return YES;
    }
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[cls new]];
    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
