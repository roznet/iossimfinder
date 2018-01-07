//  MIT Licence
//
//  Created on 18/11/2014.
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

#import "ISSimulatorOrganizer.h"
#import "RZUtils/RZUtils.h"
#import "RZUtilsOSX/RZUtilsOSX.h"
#import "ISAppGlobal.h"
#import "ISSimulatorDevice.h"

NSString * kNotifyOrganizerListChanged = @"kNotifyOrganizerListChanged";

@interface ISSimulatorOrganizer ()
@property (nonatomic,retain) NSMutableArray * devices;
@end

@implementation ISSimulatorOrganizer

-(ISSimulatorOrganizer*)init{
    self = [super init];
    if (self) {
        //[self performSelector:@selector(getSim) onThread:[ISAppGlobal worker] withObject:nil waitUntilDone:NO];
    }
    return self;
}

-(void)refreshAll{
    [self performSelector:@selector(getSim) onThread:[ISAppGlobal worker] withObject:nil waitUntilDone:NO];
}

#pragma mark - Find Simulators

-(void)getSim{
    NSError * err = nil;
    NSString * basepath = [ISSimulatorDevice basePath];
    RZLog(RZLogInfo, @"Refresh Start %@", basepath);
    NSArray * devices = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:basepath error:&err];
    NSMutableArray * rv = [NSMutableArray arrayWithCapacity:devices.count];

    for (NSString * bundle in devices) {
        ISSimulatorDevice * device = [ISSimulatorDevice deviceForIdentifier:bundle];
        if (device && device.countOfApplications > 0) {
            [rv addObject:device];
        }
    }
    RZLog(RZLogInfo, @"Refresh Done Found %@", @(devices.count));
    [rv sortUsingSelector:@selector(compareToDevice:)];

    self.devices = rv;
    [self performSelectorOnMainThread:@selector(notifyChange) withObject:nil waitUntilDone:NO];

}

-(void)getSimXCRun{
    RZTaskRunner * task = [RZTaskRunner runTask:@"/usr/bin/xcrun"
                                           args:@[ @"simctl", @"list", @"devices"]];
    NSArray * lines = [task.standardOutput componentsSeparatedByString:@"\n"];
    NSError * error = nil;
    NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:@" +([A-Za-z0-9 ]+) \\(([-0-9A-Z]+)\\)" options:0 error:&error];
    self.devices = [NSMutableArray arrayWithCapacity:lines.count];
    for (NSString * line in lines) {
        if ([line hasPrefix:@"-- "]) {
        }else{
            NSArray * matches = [regex matchesInString:line options:0 range:NSMakeRange(0, line.length)];
            if(matches.count > 0){
                NSTextCheckingResult * found = matches[0];
                NSString * bundle = [line substringWithRange:[found rangeAtIndex:2]];
                [self.devices addObject:[ISSimulatorDevice deviceForIdentifier:bundle]];
            }
        }
    }

    [self performSelectorOnMainThread:@selector(notifyChange) withObject:nil waitUntilDone:NO];
}

#pragma mark - Device Access

-(void)notifyChange{
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyOrganizerListChanged object:nil];
}

-(NSUInteger)count{
    return self.devices.count;
}
-(ISSimulatorDevice*)deviceAtIndex:(NSUInteger)idx{
    return self.devices[ idx ];
}
-(NSString*)deviceNameAtIndex:(NSUInteger)idx{
    return [[self deviceAtIndex:idx] deviceName];
}
-(ISSimulatorDevice*)deviceForUID:(NSString*)uid{
    ISSimulatorDevice * rv = nil;
    if (uid) {
        for (ISSimulatorDevice * one in self.devices) {
            if ([one.deviceUID isEqualToString:uid]) {
                rv = one;
                break;
            }
        }
    }
    return rv;
}

-(ISSimulatorApplication*)applicationForIdentifier:(NSString*)identifier inDeviceUID:(NSString*)uid{
    ISSimulatorDevice * device = [self deviceForUID:uid];
    ISSimulatorApplication * rv = [device applicationForIdentifier:identifier];
    return rv;
}
@end
