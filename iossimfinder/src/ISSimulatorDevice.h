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


#import <Foundation/Foundation.h>
@class ISSimulatorApplication;

extern NSString * kSimulatorDeviceDirectorySecureBookmark;
extern NSString * kSimulatorDeviceDirectory;

@interface ISSimulatorDevice : NSObject
+(ISSimulatorDevice*)deviceForIdentifier:(NSString*)identifier;

-(NSString*)path;
-(NSString*)applicationBundlePath;
-(NSString*)applicationDataContainerPath;

-(NSUInteger)countOfApplications;
-(NSString*)applicationNameAtIndex:(NSUInteger)idx;
-(NSImage*)applicationIconAtIndex:(NSUInteger)idx;
-(ISSimulatorApplication*)applicationAtIndex:(NSUInteger)idx;
-(ISSimulatorApplication*)applicationForIdentifier:(NSString*)identifier;

-(BOOL)isSameDevice:(ISSimulatorDevice*)other;
-(BOOL)isIphone;

-(NSComparisonResult)compareToDevice:(ISSimulatorDevice*)other;

-(NSString*)deviceName;
-(NSString*)deviceType;
-(NSString*)deviceUID;
-(NSString*)deviceRunTime;

-(NSDictionary*)appsDataContainers;
+(NSString*)basePath;

+(NSString*)guessBasePath;
+(BOOL)requiresAccessAuthorization;

@end
