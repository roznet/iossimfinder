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

#import "ViewController.h"
#import "ISAppGlobal.h"
#import "ISDataSourceApplications.h"
#import "ISDataSourceDevices.h"
#import "ISDataSourceDownloads.h"
#import "ISSimulatorApplication.h"
#import "ISSimulatorDataContainer.h"
#import "RZUtils/RZUtils.h"

NSString * kExecuteAction = @"kExecuteAction";

@interface ViewController ()
@property (nonatomic,retain) ISDataSourceDevices * dataSourceDevices;
@property (nonatomic,retain) ISDataSourceApplications * dataSourceApplications;
@property (nonatomic,retain) ISDataSourceDownloads * dataSourceDownload;

@property (nonatomic,retain) NSWindowController * helpWindow;
@property (nonatomic,retain) NSString * selectedDeviceUID;
@property (nonatomic,retain) NSString * selectedApplicationIdentifier;

@end

@implementation ViewController


-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)viewDidAppear{
    [super viewDidAppear];
    [self performSelectorOnMainThread:@selector(getAuthorization) withObject:nil waitUntilDone:NO];

}

- (void)viewDidLoad {
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(organizerChanged)
                                                 name:kNotifyOrganizerListChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceChanged)
                                                 name:kNotifyDeviceChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationChanged)
                                                 name:kNotifyApplicationChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadChanged) name:kNotifyDownloadChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(executeAction:) name:kExecuteAction object:nil];


    self.dataSourceApplications = [ISDataSourceApplications dataSourceForDevice:nil];
    self.appTableView.dataSource = self.dataSourceApplications;
    self.appTableView.delegate = self.dataSourceApplications;

    self.dataSourceDevices = [ISDataSourceDevices dataSourceForOrganizer:nil];
    self.simTableView.dataSource = self.dataSourceDevices;
    self.simTableView.delegate = self.dataSourceDevices;

    self.dataSourceDownload = [ISDataSourceDownloads dataSourceFor:nil];
    self.downloadTableView.dataSource = self.dataSourceDownload;
    self.downloadTableView.delegate = self.dataSourceDownload;

    self.deviceTerminalButton.hidden = NO;
    self.appTerminalButton.hidden = NO;
    self.dataTerminalButton.hidden = NO;
    self.downloadTerminalButton.hidden = NO;

    [self performSelectorOnMainThread:@selector(syncData) withObject:nil waitUntilDone:NO];
}

-(void)getAuthorization{
    if ([ISSimulatorDevice requiresAccessAuthorization]) {
        RZLog( RZLogInfo, @"Authorization Ask %@", [ISSimulatorDevice guessBasePath]);
        NSOpenPanel * panel = [NSOpenPanel openPanel];
        [panel setCanChooseDirectories:true];
        [panel setShowsHiddenFiles:true];
        [panel setPrompt:@"Authorize"];
        [panel setMessage:@"You need to authorize access to the Simulator Devices Directory"];
        [panel setDirectoryURL:[NSURL URLWithString:[ISSimulatorDevice guessBasePath]]];
        [panel runModal];

        NSData * data = [panel.URL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                            includingResourceValuesForKeys:nil relativeToURL:nil error:nil];
        NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
        [prefs setObject:data forKey:kSimulatorDeviceDirectorySecureBookmark];
        [prefs setObject:panel.URL.path forKey:kSimulatorDeviceDirectory];

        [prefs synchronize];
    }
    [[ISAppGlobal organizer] refreshAll];
}

#pragma mark - selected
-(ISSimulatorApplication*)selectedApplication{
    ISSimulatorApplication * rv = [[ISAppGlobal organizer] applicationForIdentifier:self.selectedApplicationIdentifier inDeviceUID:self.selectedDeviceUID];
    return rv;
}

-(ISSimulatorDataContainer*)selectedDataContainer{
    ISSimulatorApplication * app = [self selectedApplication];
    return [app dataContainer];
}

-(ISSimulatorDevice*)selectedDevice{
    return [self.organizer deviceForUID:self.selectedDeviceUID];
}
-(ISSimulatorDataContainer*)selectedDownloadDataContainer{
    NSArray * containers = [[self selectedApplication] downloadContainers];
    NSInteger row = self.downloadTableView.selectedRow;
    if (row >= 0 && row < containers.count) {
        return containers[row];
    }
    return nil;
}

#pragma mark - button open actions


-(NSString*)directoryPathForIdenfier:(NSString *)identifier{
    NSString * rv = nil;
    if ([identifier hasPrefix:@"data"]) {
        ISSimulatorDataContainer * container = [[self selectedApplication] dataContainer];
        rv = [container containerDirectory];
    }else if ([identifier hasPrefix:@"device"]){
        rv = [[self selectedDevice] path];
    }else if ([identifier hasPrefix:@"application"]){
        rv = [[self selectedApplication] bundlePath];
    }else if ([identifier hasPrefix:@"download"]){
        rv = [[self selectedDownloadDataContainer] containerDirectory];
    }
    return rv;
}

-(IBAction)executeAction:(NSNotification*)notification{
    NSString*action = notification.object;
    if ([action hasSuffix:@"finder"]) {
        [self openInFinder:action];
    }else if ([action hasSuffix:@"terminal"]){
        [self openInTerminal:action];
    }else if ([action hasSuffix:@"clipboard"]){
        [self copyToClipboard:action];
    }
}

- (IBAction)openInFinder:(id)sender {
    NSString * identifier = [sender respondsToSelector:@selector(identifier)]? [sender identifier]:sender;
    NSString * documentPath = [self directoryPathForIdenfier:identifier];
    if (documentPath) {
        if ([identifier hasPrefix:@"application"]) {
            [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[ [[NSURL alloc] initFileURLWithPath:documentPath]]];
        }else{
            [[NSWorkspace sharedWorkspace] openURL:[[NSURL alloc] initFileURLWithPath:documentPath]];
        }
        [self applicationRefresh];
    }
}
- (IBAction)openInTerminal:(id)sender {
    NSString * identifier = [sender respondsToSelector:@selector(identifier)]? [sender identifier]:sender;
    NSString * documentPath = [self directoryPathForIdenfier:identifier];
    if (documentPath) {
            NSString * src = [NSString stringWithFormat:@"tell application \"Terminal\"\ntell window 1\ndo script \"cd '%@'\"\nactivate\nend tell\nend tell\n",
                              documentPath];
            NSAppleScript * as = [[NSAppleScript alloc] initWithSource:src];
            NSDictionary * error = nil;
            [as compileAndReturnError:&error];
            [as executeAndReturnError:&error];
            [self applicationRefresh];
        }

}
- (IBAction)copyToClipboard:(id)sender {
    NSString * identifier = [sender respondsToSelector:@selector(identifier)]? [sender identifier]:sender;
    NSString * documentPath = [self directoryPathForIdenfier:identifier];
    if (documentPath) {
        NSPasteboard * paste = [NSPasteboard generalPasteboard];
        [paste clearContents];
        [paste writeObjects:@[ documentPath]];
        [self applicationRefresh];
    }
}
- (IBAction)showHelp:(id)sender {
    self.helpWindow = [[NSWindowController alloc] initWithWindowNibName:@"HelpWindow" owner:self];
    [self.helpWindow showWindow:self];
}

- (IBAction)closeHelp:(id)sender {
    self.helpWindow = nil;
}


#pragma mark - notifications


-(void)organizerChanged{
    if (self.organizer==nil) {
        self.organizer =[ISAppGlobal organizer];
        [self.dataSourceDevices changeOrganizer:self.organizer];
    }
    [self.simTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    [self.appTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    [self applicationRefresh];
}

-(void)deviceChanged{
    NSInteger deviceIdx =self.simTableView.selectedRow;
    if (deviceIdx>=0) {
        ISSimulatorDevice * device = [self.organizer deviceAtIndex:deviceIdx];
        self.selectedDeviceUID = device.deviceUID;
        if (![self.dataSourceApplications isSameDevice:device]) {
            [self.dataSourceApplications changeDevice:device];
            [self.appTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
            [self applicationRefresh];
        }
    }
}

-(void)applicationChanged{
    ISSimulatorDevice * device = [self selectedDevice];
    if (self.appTableView.selectedRow >=0 ) {
        ISSimulatorApplication * app = [device applicationAtIndex:self.appTableView.selectedRow];
        self.selectedApplicationIdentifier = [app appIdentifier];
        [app findDownloadContainers];
        [self.dataSourceDownload changeApplication:app];
    }

    [self applicationRefresh];
}

-(void)applicationRefresh{

    [self performSelectorOnMainThread:@selector(syncData) withObject:nil waitUntilDone:NO];
    [self.downloadTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];

}
-(void)downloadChanged{
    [self performSelectorOnMainThread:@selector(syncData) withObject:nil waitUntilDone:NO];
}

#pragma mark - sync data

-(void)syncData{
    ISSimulatorDevice * device = [self selectedDevice];
    ISSimulatorApplication * app = [self selectedApplication];
    ISSimulatorDataContainer * container = [app dataContainer];
    ISSimulatorDataContainer * download = [self selectedDownloadDataContainer];

    BOOL disableApp  = true;
    BOOL disableDevice = true;
    BOOL disableData = true;
    BOOL disableDownload = true;

    if (device) {
        disableDevice = false;
        self.deviceType.stringValue = [device deviceType];
        self.deviceUUID.stringValue = [device deviceUID];
        self.deviceVersion.stringValue = [device deviceRunTime];
    }

    self.deviceVersion.enabled = !disableDevice;
    self.deviceUUID.enabled = !disableDevice;
    self.deviceType.enabled = !disableDevice;
    self.deviceTerminalButton.enabled = !disableDevice;
    self.deviceFinderButton.enabled = !disableDevice;
    self.deviceClipboardButton.enabled = !disableDevice;

    if (app) {
        self.appVersion.stringValue = [app version];
        self.appBuild.stringValue = [app build];
        self.appIdentifier.stringValue = [app appIdentifier];
        self.appUUID.stringValue = [app appBundleUID];
        self.appIcon.image = [app icon];
        self.appName.stringValue = [app displayName];
        disableApp = false;

    }

    self.appName.enabled = !disableApp;
    self.appBuild.enabled = !disableApp;
    self.appIdentifier.enabled = !disableApp;
    self.appVersion.enabled = !disableApp;
    self.appUUID.enabled = !disableApp;
    self.appFinderButton.enabled = !disableApp;
    self.appClipboardButton.enabled =!disableApp;
    self.appTerminalButton.enabled = !disableApp;

    if (download) {
        disableDownload = false;
    }

    self.downloadFinderButton.enabled = !disableDownload;
    self.downloadClipboardButton.enabled = !disableDownload;
    self.downloadTerminalButton.enabled = !disableDownload;


    if (container) {
        self.dataUUID.stringValue = [container containerUID];
        self.dataModifiedDate.stringValue = [NSString stringWithFormat:@"%@", container.lastModifiedDate];
        disableData = false;
    }
    self.dataUUID.enabled = !disableData;
    self.dataFinderButton.enabled = !disableData;
    self.dataModifiedDate.enabled = !disableData;
    self.dataClipboardButton.enabled = !disableData;
    self.dataTerminalButton.enabled = !disableData;

    if (disableDevice) {
        self.deviceType.stringValue = NSLocalizedString(@"None", @"Disabled");
        self.deviceUUID.stringValue = NSLocalizedString(@"None", @"Disabled");
        self.deviceVersion.stringValue = NSLocalizedString(@"None", @"Disabled");
    }
    if (disableApp) {
        self.appVersion.stringValue = NSLocalizedString(@"None", @"Selected");
        self.appBuild.stringValue = NSLocalizedString(@"None", @"Selected");
        self.appIdentifier.stringValue = NSLocalizedString(@"None", @"Selected");
        self.appName.stringValue = NSLocalizedString(@"None", @"Selected");
        self.appUUID.stringValue = NSLocalizedString(@"None", @"Selected");
        self.appIcon.image = nil;
    }
    if (disableData) {
        self.dataUUID.stringValue = NSLocalizedString(@"None", @"Selected");
        self.dataModifiedDate.stringValue = NSLocalizedString(@"None", @"Selected");
    }
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

@end
