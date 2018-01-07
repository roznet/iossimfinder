//  MIT Licence
//
//  Created on 20/11/2014.
//
//  Copyright (c) 2014 Brice Rosenzweig.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//  

#import "ISSimulatorDevice.h"
#import "RZUtilsOSX/RZUtilsOSX.h"
#import "ISAppGlobal.h"
#import "ISSimulatorApplication.h"
#import "ISSimulatorDataContainer.h"
#import "RZUtils/RZUtils.h"


NSString * kSimulatorDeviceDirectorySecureBookmark = @"kSimulatorDeviceDirectorySecureBookmark";
NSString * kSimulatorDeviceDirectory = @"kSimulatorDeviceDirectory";

@interface ISSimulatorDevice ()
@property (nonatomic,retain) NSString * identifier;
@property (nonatomic,retain) NSString * name;
@property (nonatomic,retain) NSArray * applications;
@property (nonatomic,retain) NSDictionary * info;
@end

@implementation ISSimulatorDevice

+(ISSimulatorDevice*)deviceForIdentifier:(NSString*)identifier{
    ISSimulatorDevice * rv = [[ISSimulatorDevice alloc] init];
    if (rv) {
        rv.identifier = identifier;
        if (![rv findApps]){
            rv = nil;
        };
    }
    return rv;
}

+(BOOL)requiresAccessAuthorization{
    static BOOL checked = false;
    NSString * guess = [self guessBasePath];
    BOOL rv = false;

    if (!checked) {
        NSData * def  = [[NSUserDefaults standardUserDefaults] objectForKey:kSimulatorDeviceDirectorySecureBookmark];
        if (def) {
            NSURL* outURL = [NSURL URLByResolvingBookmarkData:def
                                                      options:NSURLBookmarkResolutionWithSecurityScope
                                                relativeToURL:nil
                                          bookmarkDataIsStale:nil error:nil];
            BOOL rv = [outURL startAccessingSecurityScopedResource];
            if (!rv) {
                RZLog(RZLogInfo, @"Failed to use Security Bookmark for %@", outURL.path);
            }else{
                RZLog(RZLogInfo, @"Used Security Bookmark for %@", outURL.path);
            }
        }else{
            RZLog(RZLogInfo, @"No Security Bookmark");
        }
        checked = true;
    }
    if([[NSFileManager defaultManager]  isReadableFileAtPath:guess]){
        rv = false;
        RZLog(RZLogInfo, @"Readable %@", guess);
    }else{
        rv = true;
        RZLog(RZLogInfo, @"Failed %@", guess);
    }
    return rv;
}

+(NSString*)guessBasePath{
    NSString * guess = NSHomeDirectory();
    NSString * sandbox = @"Library/Containers/net.ro-z.iOS-Simulator-Finder";
    NSRange range = [guess rangeOfString:sandbox];
    if (range.location != NSNotFound) {
        guess = [guess substringToIndex:range.location];
    }
    return [guess stringByAppendingPathComponent:@"Library/Developer/CoreSimulator/Devices"];
}
+(NSString*)basePath{
    return [ISSimulatorDevice guessBasePath];
    //return [NSString stringWithFormat:@"%@/Library/Developer/CoreSimulator/Devices", NSHomeDirectory()];
}

#pragma mark - Paths

-(NSString*)path{
    return [NSString stringWithFormat:@"%@/%@", [ISSimulatorDevice basePath], self.identifier];
}

-(NSString*)applicationBundlePath{
    return [NSString stringWithFormat:@"%@/%@/data/Containers/Bundle/Application", [ISSimulatorDevice basePath], self.identifier];
}
-(NSString*)applicationDataContainerPath{
    return [NSString stringWithFormat:@"%@/%@/data/Containers/Data/Application", [ISSimulatorDevice basePath], self.identifier];
}
-(NSString*)applicationPluginContainerPath{
    return [NSString stringWithFormat:@"%@/%@/data/Containers/Data/PluginKitPlugin", [ISSimulatorDevice basePath], self.identifier];
}
-(NSString*)applicationLaunchMapPath{
    return [NSString stringWithFormat:@"%@/%@/data/Library/MobileInstallation/LastLaunchServicesMap.plist", [ISSimulatorDevice basePath], self.identifier];
}

#pragma mark - Detection

-(BOOL)findApps{
    /* sample info file
     UDID = "1869944B-31A4-407F-AF8D-5AAEB4914355";
     deviceType = "com.apple.CoreSimulator.SimDeviceType.iPhone-4s";
     name = "iPhone 4s";
     runtime = "com.apple.CoreSimulator.SimRuntime.iOS-8-1";
     state = 1;
     */
    self.info = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/device.plist", self.path]];
    if (!self.info) {
        return false;
    }
    self.name = self.info[@"name"];
    if (self.name && [self.name rangeOfString:@"Watch"].location != NSNotFound){
        NSLog(@"Watch %@", self.name);
    }

    NSError * e = nil;
    NSArray * appdirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self applicationBundlePath] error:&e];

    if (appdirs.count>0) {
        NSMutableArray * apps = [NSMutableArray array];

        NSDictionary * downloads = [ISSimulatorApplication allDownloadContainers];
        NSDictionary * containers = [self appsDataContainers];
        NSDictionary * plugins = [self plugins];

        for (NSString * bundledir in appdirs) {
            ISSimulatorApplication * app = [ISSimulatorApplication applicationFor:self andBundleUID:bundledir];
            ISSimulatorDataContainer * container = containers[app.appIdentifier];

            if (container==nil && plugins[app.appIdentifier]) {
                for (NSString * pluginId in plugins[app.appIdentifier]) {
                    if (containers[pluginId]) {
                        container = containers[pluginId];
                    }
                }
            }
            [app noticeDataContainer:container];
            [app noticeExtensions:plugins];
            [app noticeDownloadContainers:downloads];
            if(app.isValid){
                [apps addObject:app];
            }
        }
        [apps sortUsingSelector:@selector(compareToApplication:)];
        self.applications = apps;
    }else{
        self.applications = nil;
    }
    return true;
}

-(NSDictionary*)plugins{
    NSMutableDictionary * rv =[NSMutableDictionary dictionary];
    NSDictionary * launch = [NSDictionary dictionaryWithContentsOfFile:[self applicationLaunchMapPath]];

    if (launch && launch[@"User"]) {
        NSDictionary * userInfo = launch[@"User"];
        for (NSString * appIdentifier in userInfo) {
            NSDictionary * appInfo = userInfo[appIdentifier];
            NSString * appIdentifier = appInfo[@"CFBundleIdentifier"];
            rv[appIdentifier] = [NSMutableArray array];
        }
    }
    if (launch && launch[@"PluginKitPlugin"]) {
        for (NSString * pluginId in launch[@"PluginKitPlugin"]) {
            NSDictionary * pluginValues = launch[@"PluginKitPlugin"][pluginId];
            NSMutableArray * existings = pluginValues[@"PluginOwnerBundleID"] ? rv[ pluginValues[@"PluginOwnerBundleID"] ] : nil;
            if (existings) {
                [existings addObject:pluginId];
            }
        }
    }
    return rv;
}

-(NSDictionary*)appsDataContainers{
    NSMutableDictionary * rv = [NSMutableDictionary dictionary];
    NSError * e = nil;

    NSDictionary * launch = [NSDictionary dictionaryWithContentsOfFile:[self applicationLaunchMapPath]];

    // First look for application identified by the AppLaunch
    NSMutableDictionary * done = [NSMutableDictionary dictionary];
    if (launch && launch[@"User"]) {
        NSDictionary * userInfo = launch[@"User"];
        for (NSString * appIdentifier in userInfo) {
            NSDictionary * appInfo = userInfo[appIdentifier];
            NSString * appIdentifier = appInfo[@"CFBundleIdentifier"];
            ISSimulatorDataContainer * container = [ISSimulatorDataContainer containerForAppInfo:appInfo];
            if (container) {
                rv[appIdentifier] =container;
                done[container.containerUID] = container;
            }

            if (launch && launch[@"PluginKitPlugin"]) {
                for (NSString * pluginId in launch[@"PluginKitPlugin"]) {
                    NSDictionary * pluginValues = launch[@"PluginKitPlugin"][pluginId];
                    if ([pluginValues[@"PluginOwnerBundleID"] isEqualToString:appIdentifier]) {
                        ISSimulatorDataContainer * container = [ISSimulatorDataContainer containerForAppInfo:pluginValues];
                        if (container) {
                            rv[pluginId] = container;
                            done[container.containerUID] = container;
                        }
                    }
                }
            }
        }
    }

    // Second look for container with a simneedle file in app containers
    NSString * containerPath = [self applicationDataContainerPath];
    NSArray * appdirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:containerPath error:&e];
    for (NSString * dir in appdirs) {
        if (done[dir]) {
            continue;
        }
        ISSimulatorDataContainer * dataContainer = [ISSimulatorDataContainer containerFor:dir withBasePath:containerPath];
        if (dataContainer) {
            rv[dataContainer.appIdentifier] = dataContainer;
            done[dataContainer.containerUID] = dataContainer;
        }
    }

    containerPath = [self applicationPluginContainerPath];
    appdirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:containerPath error:&e];
    for (NSString * dir in appdirs) {
        if (done[dir]) {
            continue;
        }
        ISSimulatorDataContainer * dataContainer = [ISSimulatorDataContainer containerFor:dir withBasePath:containerPath];
        if (dataContainer) {
            rv[dataContainer.appIdentifier] = dataContainer;
            done[dataContainer.containerUID] = dataContainer;
        }
    }


    return rv;
}

#pragma mark - Application Access

-(NSUInteger)countOfApplications{
    return self.applications.count;
}
-(ISSimulatorApplication*)applicationAtIndex:(NSUInteger)idx{
    return idx < self.applications.count ?  self.applications[idx] : nil;
}
-(NSString*)applicationNameAtIndex:(NSUInteger)idx{
    return [[self applicationAtIndex:idx] applicationName];
}

-(NSImage*)applicationIconAtIndex:(NSUInteger)idx{
    return [[self applicationAtIndex:idx] icon];
}

-(ISSimulatorApplication*)applicationForIdentifier:(NSString*)identifier{
    if (identifier) {
        for (ISSimulatorApplication*app in self.applications) {
            if([[app appIdentifier] isEqualToString:identifier]){
                return app;
            }
        }
    }
    return nil;
}

#pragma mark - Device Information

-(NSComparisonResult)compareToDevice:(ISSimulatorDevice*)other{
    NSNumber * one = @( [self.deviceRunTime doubleValue]);
    NSNumber * two = @( [other.deviceRunTime doubleValue]);

    NSComparisonResult rv = [two compare:one] ;

    if (rv == NSOrderedSame) {
        if (self.countOfApplications > other.countOfApplications) {
            rv = NSOrderedAscending;
        }else if (self.countOfApplications < other.countOfApplications){
            rv = NSOrderedDescending;
        }else{
            rv = [self.deviceName compare:other.deviceName];
        }
    }
    return rv;
}

-(BOOL)isSameDevice:(ISSimulatorDevice*)other{
    return [self.identifier isEqualToString:other.identifier];
}
-(BOOL)isIphone{
    return [self.name rangeOfString:@"iPhone"].location != NSNotFound;
}

-(NSString*)deviceUID{
    NSString * rv = self.info[@"UDID"];
    if (rv == nil) {
        rv = NSLocalizedString(@"None", @"InfoKey");
    }
    return rv;
}

-(NSString*)lastElemForKey:(NSString*)key missing:(NSString*)elem{
    NSString * rv = self.info[key];
    if (rv) {
        NSArray * split = [rv componentsSeparatedByString:@"."];
        if (split.count>0) {
            rv = [split lastObject];
        }
    }else{
        rv = elem;
    }
    return rv;
}

-(NSString*)deviceType{
    return [self lastElemForKey:@"deviceType" missing:NSLocalizedString(@"None", @"InfoKey")];
}

-(NSString*)deviceRunTime{
    NSString * raw = [self lastElemForKey:@"runtime" missing:NSLocalizedString(@"Unknown", @"InfoKey")];
    if ([raw hasPrefix:@"iOS-"]) {
        raw = [raw substringFromIndex:4];
    }
    return [raw stringByReplacingOccurrencesOfString:@"-" withString:@"."];
}
-(NSString*)deviceName{
    return self.name;
}

@end
