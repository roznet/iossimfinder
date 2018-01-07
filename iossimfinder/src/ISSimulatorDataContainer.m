//  MIT Licence
//
//  Created on 24/11/2014.
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

#import "ISSimulatorDataContainer.h"

#define kMostRecent @"MostRecent"
#define kFileSize   @"FileSize"
#define kFileCount  @"FileCount"

@interface ISSimulatorDataContainer ()
@property (nonatomic,retain) NSString * appIdentifier;
@property (nonatomic,retain) NSString * containerUID;
@property (nonatomic,retain) NSDate * lastModifiedDate;
@property (nonatomic,retain) NSString * containerDirectory;
@property (nonatomic,retain) NSString * appVersion;
@property (nonatomic,assign) NSUInteger totalFileSize;
@property (nonatomic,assign) NSUInteger fileCount;
@end

@implementation ISSimulatorDataContainer

-(void)setDirectoryInfo:(NSString*)path{
    NSError * error = nil;
    NSDictionary * attribute = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];

    NSDate * mostrecent = attribute.fileModificationDate;
    NSUInteger totalSize = 0;

    NSArray * files = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[NSURL fileURLWithPath:path]
                                                    includingPropertiesForKeys:@[NSURLAttributeModificationDateKey,NSURLFileSizeKey]
                                                                       options:0
                                                                         error:&error];
    for (NSURL * url in files) {
        if ([url.path.lastPathComponent hasPrefix:@".simneedle."]) {
            self.appIdentifier = [url.path.lastPathComponent substringFromIndex:11];
        }

        NSDictionary * attr = [url resourceValuesForKeys:@[NSURLAttributeModificationDateKey,NSURLFileSizeKey] error:&error];
        if (mostrecent == nil || [mostrecent compare:attr[NSURLAttributeModificationDateKey] ]== NSOrderedDescending) {
            mostrecent =attr[NSURLAttributeModificationDateKey];
        }

        totalSize += [attr[NSURLFileSizeKey] integerValue];
    }
    self.fileCount = files.count;
    self.totalFileSize = totalSize;
    self.lastModifiedDate = mostrecent;
}


+(ISSimulatorDataContainer*)downloadContainerFor:(NSString*)dir withBasePath:(NSString*)downloadPath {
    ISSimulatorDataContainer * rv = nil;
    NSString * checkdir = [NSString stringWithFormat:@"%@/%@/AppData/Documents", downloadPath, dir];
    NSDictionary * info = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/%@/AppDataInfo.plist", downloadPath,dir]];
    NSString * appidentifier = info[@"CFBundleIdentifier"];
    NSString * version = info[@"XCExecutableVersion"];

    if (appidentifier) {
        rv = [[ISSimulatorDataContainer alloc] init];
        rv.containerUID = dir;
        rv.containerDirectory = [NSString stringWithFormat:@"%@/%@/AppData", downloadPath,dir];
        [rv setDirectoryInfo:checkdir];
        rv.appIdentifier = appidentifier;
        rv.appVersion = version;
    }
    return rv;
}

+(ISSimulatorDataContainer*)containerForAppInfo:(NSDictionary*)info{
    ISSimulatorDataContainer * rv = nil;
    NSString * path = info[@"Container"];
    NSString * appidentifier = info[@"CFBundleIdentifier"];
    if(path && appidentifier && [[NSFileManager defaultManager] fileExistsAtPath:path]){
        NSString * checkdir = [NSString stringWithFormat:@"%@/Documents", path];

        rv = [[ISSimulatorDataContainer alloc] init];
        rv.containerUID = [path lastPathComponent];
        rv.containerDirectory = path;
        [rv setDirectoryInfo:checkdir];
        rv.appIdentifier = appidentifier;
    }

    return rv;

}

+(ISSimulatorDataContainer*)containerFor:(NSString*)dir withBasePath:(NSString*)containerPath{
    ISSimulatorDataContainer * rv = nil;
    NSString * checkdir = [NSString stringWithFormat:@"%@/%@/Documents", containerPath, dir];
    rv = [[ISSimulatorDataContainer alloc] init];
    rv.containerUID = dir;
    [rv setDirectoryInfo:checkdir];
    rv.containerDirectory = [NSString stringWithFormat:@"%@/%@", containerPath,dir];

    return rv.appIdentifier ? rv : nil;
}

-(NSString*)formatTotalFileSize{
    NSString * unit = @"b";
    double val = self.totalFileSize;
    if (val>1024.) {
        val/=1024.;
        unit = @"Kb";
    }
    if (val>1024.) {
        val/=1024.;
        unit = @"Mb";
    }
    if (val>1024.) {
        val/=1024.;
        unit = @"Gb";
    }
    return [NSString stringWithFormat:@"%.1f %@", val, unit];
}

-(NSComparisonResult)compare:(ISSimulatorDataContainer*)other{
    return [other.lastModifiedDate compare:self.lastModifiedDate];
}

@end
