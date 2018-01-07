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

#import "ISAppGlobal.h"
#import "AppDelegate.h"
#import "RZUtils/RZUtils.h"

NS_INLINE AppDelegate* ISAppDelegate(){
    return (AppDelegate*)[[NSApplication sharedApplication] delegate];
}

@implementation ISAppGlobal

+(NSMutableDictionary*)settings{
    static NSMutableDictionary * dict = nil;
    if (dict) {
        dict = [NSMutableDictionary dictionary];
    }
    return dict;
}
+(NSThread*)worker{
    return [ISAppDelegate() worker];
}
+(ISSimulatorOrganizer*)organizer{
    return [ISAppDelegate() organizer];
}

+(void)saveSwiftFile{
    NSError * e = nil;
    NSSavePanel * save = [NSSavePanel savePanel];
    [save setMessage:@"Choose the location to save the swift file"];
    [save setAllowedFileTypes:@[ @"swift"]];
    [save setNameFieldStringValue:@"rzneedle"];
    if([save runModal] == NSFileHandlingPanelOKButton){
        NSString * header = [NSString stringWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"needle.swifttt"]
                                                      encoding:NSUTF8StringEncoding error:&e];
        if (e==nil) {
            RZLog(RZLogInfo, @"saved %@", save.URL);
            [header writeToURL:save.URL atomically:YES encoding:NSUTF8StringEncoding error:&e];
        }
    }
}

+(void)saveHeaderFile{
    NSError * e = nil;
    NSSavePanel * save = [NSSavePanel savePanel];
    [save setMessage:@"Choose the location to save the header file"];
    [save setAllowedFileTypes:@[ @"h"]];
    [save setNameFieldStringValue:@"rzneedle"];
    if([save runModal] == NSFileHandlingPanelOKButton){
        NSString * header = [NSString stringWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"needle.hhh"]
                                                      encoding:NSUTF8StringEncoding error:&e];
        if (e==nil) {
            RZLog(RZLogInfo, @"saved %@", save.URL);
            [header writeToURL:save.URL atomically:YES encoding:NSUTF8StringEncoding error:&e];
        }
    }
}

@end
