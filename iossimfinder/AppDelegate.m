//  MIT Licence
//
//  Created on 16/11/2014.
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

#import "AppDelegate.h"
#import "ISSimulatorOrganizer.h"
#import "RZUtils/RZUtils.h"
#import "ISAppGlobal.h"
#import "ViewController.h"

NSString * kInstallID = @"kInstallID";
NSString * kBugFileName = @"bugreport.zip";

@interface AppDelegate ()
@property (nonatomic,retain) NSWindowController * preferenceWindow;
@property (nonatomic,retain) RZRemoteDownload * remoteVersion;
@property (nonatomic,retain) RZRemoteDownload * remoteBugReport;
@end

@implementation AppDelegate

#pragma mark - Menu Actions

-(BOOL)validateMenuItem:(NSMenuItem *)menuItem{

    if (menuItem.tag == 1) {
        return [self.viewController selectedDevice] != nil;
    }else if (menuItem.tag == 2){
        return [self.viewController selectedApplication] != nil;
    }else if (menuItem.tag == 3){
        return [self.viewController selectedDataContainer] != nil;
    }else if (menuItem.tag == 4){
        return [self.viewController selectedDownloadDataContainer] != nil;
    }else if (menuItem.tag == 10){
        NSWindow * wi = [NSApp mainWindow];
        if (wi==nil) {
            return YES;
        }else{
            return NO;
        }
    }
    return YES;
}

- (IBAction)onlineHelp:(NSMenuItem*)sender {
    if (sender.tag == 20) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.ro-z.net/iossimulatorfinder/apphelp.php?app=1"]];
    }else if(sender.tag == 21){
        [self bugReport];
    }
}


- (IBAction)openFinder:(NSMenuItem*)sender {
    NSString * action = nil;
    if (sender.tag == 1) {
        action = @"devicefinder";
    }else if (sender.tag == 2){
        action = @"applicationfinder";
    }else if (sender.tag == 3){
        action = @"datafinder";
    }else if (sender.tag == 4){
        action = @"downloadfinder";
    }
    if (action) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kExecuteAction object:action];
    }
}
- (IBAction)refreshAll:(id)sender {
    [self.organizer refreshAll];
}

-(IBAction)copyClipBoard:(NSMenuItem*)sender{
    NSString * action = nil;
    if (sender.tag == 1) {
        action = @"deviceclipboard";
    }else if (sender.tag == 2){
        action = @"applicationclipboard";
    }else if (sender.tag == 3){
        action = @"dataclipboard";
    }else if (sender.tag == 4){
        action = @"downloadclipboard";
    }
    if (action) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kExecuteAction object:action];
    }
}


- (IBAction)showPreferences:(id)sender {
    self.preferenceWindow = [[NSWindowController alloc] initWithWindowNibName:@"Preferences" owner:self];
    [self.preferenceWindow showWindow:self];

}

-(IBAction)closePreferences:(id)sender{
    self.preferenceWindow = nil;
}

-(IBAction)showWindow:(id)sender{
    NSWindow * wi = [NSApp mainWindow];
    if (wi == nil) {
        if([[NSApplication sharedApplication] windows].count > 0){
            NSWindow * w = [[NSApplication sharedApplication] windows][0];
            [w makeKeyAndOrderFront:self];
        }
    }

}

#pragma mark - DevMate

- (IBAction)startActivationProcess:(id)sender {
}
#pragma mark - Application Delegate Protocol

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

    RZLog(RZLogInfo, @"============= %@ %@ =================",
          [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutable"],
          [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]);

    [self setupWorkerThread];
    // Force authorization early
    //[[NSUserDefaults standardUserDefaults] removeObjectForKey:kSimulatorDeviceDirectorySecureBookmark];
    [ISSimulatorDevice requiresAccessAuthorization];
    self.organizer = [[ISSimulatorOrganizer alloc] init];
    [self.organizer refreshAll];

    [self checkVersion];

}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

-(void)applicationWillBecomeActive:(NSNotification *)notification{
    //[self.organizer refreshAll];
}

#pragma mark - Thread Setup

-(void)setupWorkerThread{
    self.worker = [[NSThread alloc] initWithTarget:self selector:@selector(startWorkerThread) object:nil];
    [_worker setName:@"Worker"];
    [_worker start];
}

-(void)startWorkerThread{

    while (true) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantFuture]];
    }
}

#pragma mark - RemoteDelegate

-(NSString*)installID{
    NSString * uuid = [[NSUserDefaults standardUserDefaults] stringForKey:kInstallID];
    if (!uuid) {
        uuid = [[NSUUID UUID] UUIDString];
        [[NSUserDefaults standardUserDefaults] setObject:uuid forKey:kInstallID];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    return uuid;
}

-(NSDictionary*)infoDictionary{
    NSString * uuid = [self installID];
    NSProcessInfo *pInfo = [NSProcessInfo processInfo];
    NSString *osversion = [pInfo operatingSystemVersionString];

    NSString * version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    NSDictionary * rv = @{ @"version": version,
                             @"osversion": osversion,
                             @"install_id" : uuid
                             };
    return rv;
}

-(void)checkVersion{
    NSDictionary * post = [self infoDictionary];

    NSString * url = [NSString stringWithFormat:@"https://www.ro-z.net/iossimulatorfinder/check_version.php"];
    //For testing:
    //url = [NSString stringWithFormat:@"http://localhost/iossimulatorfinder/check_version.php"];
    self.remoteVersion = [[RZRemoteDownload alloc] initWithURL:url postData:post andDelegate:self];
}

-(void)bugReport{
    if (self.remoteBugReport || self.remoteVersion) {
        return;
    }
/*
    NSString * aUrl = @"https://www.ro-z.net/iossimulatorfinder/bugreport_save.php";
    //aUrl = @"http://localhost/iossimulatorfinder/bugreport_save.php";

    NSDictionary * post = [self infoDictionary];

    NSString * log = RZLogFileContent();

    NSString * bugpath = [RZFileOrganizer writeableFilePath:kBugFileName];

    OZZipFile * zipFile= [[OZZipFile alloc] initWithFileName:bugpath mode:OZZipFileModeCreate];

    OZZipWriteStream *stream= [zipFile writeFileInZipWithName:@"bugreport.log" compressionLevel:OZZipCompressionLevelBest];
    [stream writeData:[log dataUsingEncoding:NSUTF8StringEncoding]];
    [stream finishedWriting];

    [zipFile close];
    //[zipFile release];

    NSMutableDictionary * pData = [NSMutableDictionary dictionaryWithDictionary:post];
    pData[@"applicationName"] =  @"Simulator Data Finder";


    self.remoteBugReport = [[RZRemoteDownload alloc] initWithURL:aUrl
                                                      postData:pData
                                                      fileName:@"bugreport.zip"
                                                      fileData:[NSData dataWithContentsOfFile:bugpath]
                                                   andDelegate:self];
 */
}

-(void)downloadArraySuccessful:(id)connection array:(NSArray *)theArray{

}
-(void)downloadFailed:(id)connection{

}
-(void)downloadStringSuccessful:(id)connection string:(NSString *)theString{
    if (self.remoteVersion == connection) {
        NSError * err= nil;
        NSDictionary * json = [NSJSONSerialization JSONObjectWithData:[theString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&err ];
        if (json==nil) {
            RZLog(RZLogError,@"Failed to get json %@", err);
        }
        NSInteger compared = [json[@"compared"] integerValue];
        if (compared == 1) {
            NSAlert * alert = [[NSAlert alloc] init];
            alert.messageText = json[@"message"];
            alert.informativeText = [NSString stringWithFormat:@"You have version %@, the latest version is %@",
                                     [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"],
                                     json[@"new_version"]];

            [alert addButtonWithTitle:NSLocalizedString(@"Download", @"New Version")];
            [alert addButtonWithTitle:NSLocalizedString(@"Ignore this version", @"New Version")];
            [alert addButtonWithTitle:NSLocalizedString(@"Remind me later", @"New Version")];

            NSModalResponse choice = [alert runModal];
            if (choice == NSAlertFirstButtonReturn) {
                NSString * url = [NSString stringWithFormat:@"%@?version=%@&latest=%@",
                                  @"https://www.ro-z.net/iossimulatorfinder/download_version.php",
                                  [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"],
                                  json[@"new_version"]
                                  ];
                [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];

            }else if (choice == NSAlertSecondButtonReturn){
                NSLog(@"Ignore");
            }
        }
        self.remoteVersion = nil;
    }
    if (self.remoteBugReport == connection) {
        int bug_id = [theString intValue];
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://www.ro-z.net/iossimulatorfinder/bugreport.php?bug_id=%d", bug_id]]];
        self.remoteBugReport = nil;
    }
}


@end
