//
//  AppDelegate.m
//  CXDatabaseDemo
//
//  Created by Xingzhi Cheng on 13/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "Post.h"
#import "NSObject+CXDatabase.h"
#import "CXDatabase.h"

@implementation AppDelegate

@synthesize window = _window;

- (void)dealloc
{
    [_window release];
    
    [super dealloc];
}

void uncaughtExceptionHandler(NSException *exception);

void uncaughtExceptionHandler(NSException *exception) {
    NSLog(@"CRASH: %@", exception);
    NSLog(@"Stack Trace: %@", [exception callStackSymbols]);
    // Internal error reporting
}

- (void) runDatabaseTest {
    NSString * file = @"/tmp/1.db";
    
    [[NSFileManager defaultManager] removeItemAtPath:file error:nil];
    
    CXDatabase * db = [CXDatabase databaseWithPath:file];
    
    Post * p;
    
    for (int i = 100; i < 110; ++i) {
        p = [Post randomPostWithID:i];
        [p saveToDatabase:db];
    }
    
    /*
    FMResultSet * rs = [Post find:[NSDictionary dictionaryWithObject:@"104" forKey:@"idx"] inDatabase:db];
    
    while ([rs next]) {
        NSDictionary * dict = [rs resultDictionary];
        NSLog(@"%@\n", dict);
        
        p = [Post parsedFromResultDictionary:dict];
        NSLog(@"%@", [p toString]);
    }
    
    [rs close];
    */
    p = [Post findOne:[NSDictionary dictionaryWithObject:@"104" forKey:@"idx"] inDatabase:db];
    NSLog(@"FOUND : %@", [p toString]);
    
    NSLog(@"total count %d", [Post rowCountInDatabase:db]);
    
    NSLog(@"delete where idx = 104 : %d", [p removeFromDatabase:db]);
    
    NSLog(@"total count %d", [Post rowCountInDatabase:db]);
    
    NSLog(@"order by createData DESC limit 20 offset 5");
    
    FMResultSet * rs = [Post find:@"order by createDate DESC limit 20 offset 5" inDatabase:db];

    while ([rs next]) {
        NSDictionary * dict = [rs resultDictionary];
        NSLog(@"%@\n", dict);
    }

    [rs close];
    
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    [self runDatabaseTest];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
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
