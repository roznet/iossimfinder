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

#import "ISSimulatorApplication.h"
#import "ISSimulatorDevice.h"
#import "ISAppGlobal.h"
#import <Cocoa/Cocoa.h>
#import "ISSimulatorDataContainer.h"
#import "ISSimulatorAppExtension.h"
#import "RZUtilsOSX/RZUtilsOSX.h"

@interface ISSimulatorApplication ()
@property (nonatomic,retain) ISSimulatorDevice * device;
@property (nonatomic,retain) NSString * bundleUID;
@property (nonatomic,retain) NSDictionary * info;
@property (nonatomic,retain) NSString * bundleDirectory;
@property (nonatomic,retain) ISSimulatorDataContainer * lastDataContainer;
@property (nonatomic,retain) NSArray * downloadContainers;
@property (nonatomic,retain) NSDictionary * extensions;

@end

@implementation ISSimulatorApplication

/*Info Keys
 DTSDKName,
 UIFileSharingEnabled,
 CFBundleDevelopmentRegion,
 DTPlatformName,
 CFBundleDocumentTypes,
 CFBundlePackageType,
 CFBundleSupportedPlatforms,
 FacebookAppID,
 CFBundleInfoDictionaryVersion,
 CFBundleExecutable,
 UIRequiredDeviceCapabilities,
 UISupportedInterfaceOrientations~ipad,
 CFBundleURLTypes,
 UIPrerenderedIcon,
 CFBundleSignature,
 UTExportedTypeDeclarations,
 LSRequiresIPhoneOS,
 UISupportedInterfaceOrientations,
 UILaunchImages,
 UIDeviceFamily
 ----------------------------------
 CFBundleName,
 CFBundleIcons~ipad,
 CFBundleDisplayName,
 CFBundleShortVersionString,
 CFBundleIdentifier,
 CFBundleIcons,
 CFBundleVersion,
 */

+(ISSimulatorApplication*)applicationFor:(ISSimulatorDevice*)device andBundleUID:(NSString*)uid{
    ISSimulatorApplication * rv = [[ISSimulatorApplication alloc] init];
    if (rv) {
        rv.device = device;
        rv.bundleUID = uid;
        NSString * base =[NSString stringWithFormat:@"%@/%@", [device applicationBundlePath], uid];
        NSError * e = nil;
        NSArray * f = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:base error:&e];
        if (f.count >0) {
            for (NSString * one in f) {
                rv.bundleDirectory = one;
                if ([[NSFileManager defaultManager] fileExistsAtPath:rv.infofile]) {
                    rv.info = [NSDictionary dictionaryWithContentsOfFile:rv.infofile];
                    [rv findExtensions];
                    break;
                }
            }
        }
    }
    return rv;
}

-(NSComparisonResult)compareToApplication:(ISSimulatorApplication*)other{
    NSComparisonResult rv = NSOrderedSame;
    if (self.lastDataContainer && ! other.lastDataContainer) {
        rv = NSOrderedAscending;
    }else if (!self.lastDataContainer && other.lastDataContainer){
        rv = NSOrderedDescending;
    }else if(self.lastDataContainer && other.lastDataContainer){
        rv = [other.lastDataContainer.lastModifiedDate compare:self.lastDataContainer.lastModifiedDate];
    }else{
        rv = [self.applicationName compare:other.applicationName];
    }
    return rv;
}

#pragma mark - Paths

-(NSString*)bundlePath{
    return [NSString stringWithFormat:@"%@/%@/%@", [self.device applicationBundlePath], self.bundleUID,  self.bundleDirectory];
}

-(NSString*)infofile{
    return [NSString stringWithFormat:@"%@/Info.plist", [self bundlePath]];
}

-(NSString*)pluginsBundlesPath{
    return [NSString stringWithFormat:@"%@/Plugins", [self bundlePath]];
}

#pragma mark - Data Containers

-(ISSimulatorDataContainer*)dataContainer{
    NSDictionary * appContainers = [self.device appsDataContainers];
    ISSimulatorDataContainer * container = appContainers[ self.appIdentifier];
    if (container==nil && self.extensions.count) {
        for (NSString * extIdentifier in self.extensions) {
            ISSimulatorAppExtension * ext= self.extensions[extIdentifier];
            if (appContainers[ext.extensionIdentifier]) {
                container = appContainers[ext.extensionIdentifier];
            }
        }
    }

    self.lastDataContainer = container;
    return container;
}

-(void)noticeDataContainer:(ISSimulatorDataContainer*)container{
    self.lastDataContainer = container;
}

#pragma mark - Application Extensions

-(void)findExtensions{
    NSString * dir = [self pluginsBundlesPath];
    NSError * e = nil;
    NSArray * files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dir error:&e];
    NSMutableDictionary * newExt = self.extensions ? [NSMutableDictionary dictionaryWithDictionary:self.extensions] : [NSMutableDictionary dictionary];
    for (NSString * ext in files) {
        NSDictionary * info = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/%@/Info.plist", dir, ext]];
        if( info ){
            ISSimulatorAppExtension * ext = [ISSimulatorAppExtension extensionForInfo:info];
            newExt[ext.extensionIdentifier] = ext;
        }
    }
    self.extensions = newExt;
}

-(void)noticeExtensions:(NSDictionary*)extensions{
}


#pragma mark - Application Information

-(NSString*)applicationName{
    NSString * rv = self.info[@"CFBundleDisplayName"];
    if (!rv) {
        rv = self.info[@"CFBundleName"];
    }
    return rv;
}

-(NSArray*)iconsForInfo:(NSString*)key{
    NSDictionary * bundleIcons = self.info[key];
    NSMutableArray * rv = [NSMutableArray array];
    if(bundleIcons){
        for (NSString * subkey in bundleIcons) {
            NSArray * found = bundleIcons[subkey][@"CFBundleIconFiles"];
            if (found) {
                for (NSString * base in found) {
                    NSString * fn = [NSString stringWithFormat:@"%@/%@@2x.png",  [self bundlePath], base];
                    if ([[NSFileManager defaultManager] fileExistsAtPath:fn]) {
                        NSImage * one = [[NSImage alloc] initWithContentsOfFile:fn];
                        [rv addObject:one];
                    }else{
                        fn = [NSString stringWithFormat:@"%@/%@.png",  [self bundlePath], base];
                        if ([[NSFileManager defaultManager] fileExistsAtPath:fn]) {
                            NSImage * one = [[NSImage alloc] initWithContentsOfFile:fn];
                            [rv addObject:one];
                        }
                    }
                }
            }
        }
    }

    return rv;
}

-(NSImage*)icon{
    NSArray * ipadIcons = [self iconsForInfo:@"CFBundleIcons~ipad"];
    if (ipadIcons.count) {
        return ipadIcons[0];
    }
    NSArray * iphoneIcons = [self iconsForInfo:@"CFBundleIcons"];
    if (iphoneIcons.count) {
        return iphoneIcons[0];
    }
    return [NSImage imageNamed:@"missing"];
}

-(NSString*)appBundleUID{
    return self.bundleUID;
}
-(BOOL)isWatchKit{
    return [self.info[@"WKWatchKitApp"] boolValue];
}
-(BOOL)isValid{
    return self.info != nil;
}
-(NSString*)appIdentifier{
    return [self infoForKey:@"CFBundleIdentifier" missing:NSLocalizedString(@"None", @"InfoKey")];
}
/*
 CFBundleName,
 CFBundleIcons~ipad,
 CFBundleDisplayName,
 CFBundleShortVersionString,
 CFBundleIdentifier,
 CFBundleIcons,
 CFBundleVersion,
*/

-(NSString*)infoForKey:(NSString*)key missing:(NSString*)def{
    NSString * rv = self.info[key];
    if (rv == nil) {
        rv = def;
    }
    return rv;
}

-(NSString*)version{
    return [self infoForKey:@"CFBundleShortVersionString" missing:NSLocalizedString(@"None", @"InfoKey")];;
}
-(NSString*)build{
    return [self infoForKey:@"CFBundleVersion" missing:NSLocalizedString(@"None", @"InfoKey")];

}
-(NSString*)displayName{
    return self.applicationName;
}

#pragma mark - Download Containers

+(NSString*)downloadContainerDirectory{
    NSArray *docDirs = NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES);
    return docDirs.count>0?docDirs[0]:nil;
}

+(NSDictionary*)allDownloadContainers{
    NSString * dir = [ISSimulatorApplication downloadContainerDirectory];
    NSMutableDictionary * rv = [NSMutableDictionary dictionary];
    if (dir) {
        NSError * e = nil;
        NSArray * files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dir error:&e];
        for (NSString * file in files) {
            if ([file hasSuffix:@"xcappdata"]) {
                ISSimulatorDataContainer * container = [ISSimulatorDataContainer downloadContainerFor:file withBasePath:dir];
                if (container) {
                    NSMutableArray * appcontainers = rv[container.appIdentifier];
                    if (!appcontainers) {
                        appcontainers = [NSMutableArray arrayWithObject:container];
                        rv[container.appIdentifier] = appcontainers;
                    }else{
                        [appcontainers addObject:container];
                    }
                }
            }
        }
    }
    return rv;

}

-(void)noticeDownloadContainers:(NSDictionary*)containers{
    NSArray * found = containers[self.appIdentifier];
    if (found) {
        self.downloadContainers = found;
    }
}

-(NSArray*)findDownloadContainers{
    NSString * dir = [ISSimulatorApplication downloadContainerDirectory];
    NSMutableArray * rv = nil;
    if (dir) {
        NSString * identifier = self.appIdentifier;
        NSError * e = nil;
        rv =  [NSMutableArray array];
        NSArray * files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dir error:&e];
        for (NSString * file in files) {
            if ([file hasPrefix:identifier] && [file hasSuffix:@"xcappdata"]) {
                ISSimulatorDataContainer * container = [ISSimulatorDataContainer downloadContainerFor:file withBasePath:dir];
                [rv addObject:container];
            }
        }
    }
    self.downloadContainers = [rv sortedArrayUsingSelector:@selector(compare:)];
    return rv;
}

@end
