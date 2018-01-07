//  MIT Licence
//
//  Created on 12/12/2014.
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

#import "PreferenceViewController.h"
#import "ISSimulatorDevice.h"
#import "ISAppGlobal.h"
#import "RZUtils/RZUtils.h"

@interface PreferenceViewController ()

@end

@implementation PreferenceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
    NSString * path = [prefs objectForKey:kSimulatorDeviceDirectory];
    self.pathLabel.stringValue = path? path : @"Not setup";
    if (![ISSimulatorDevice requiresAccessAuthorization]) {
        self.foundCheckbox.state = NSOnState;
    }else{
        self.foundCheckbox.state = NSOffState;
    }

}
- (IBAction)selectNewAuthorize:(id)sender {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSimulatorDeviceDirectorySecureBookmark];
    RZLog( RZLogInfo, @"Authorization Ask %@", [ISSimulatorDevice guessBasePath]);
    NSOpenPanel * panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories:true];
    [panel setShowsHiddenFiles:true];
    [panel setPrompt:@"Authorize"];
    [panel setMessage:@"You need to authorize access to the Simulator Devices Directory"];
    [panel setDirectoryURL:[NSURL URLWithString:[ISSimulatorDevice guessBasePath]]];
    NSInteger rv = [panel runModal];
    if (rv == NSFileHandlingPanelOKButton) {
        NSData * data = [panel.URL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                            includingResourceValuesForKeys:nil relativeToURL:nil error:nil];
        NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
        [prefs setObject:data forKey:kSimulatorDeviceDirectorySecureBookmark];
        [prefs setObject:panel.URL.path forKey:kSimulatorDeviceDirectory];

        [prefs synchronize];
        [[ISAppGlobal organizer] refreshAll];
        self.foundCheckbox.state = NSOnState;
    }

}
- (IBAction)toggleFound:(id)sender {
    if ([sender state] == NSOffState) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSimulatorDeviceDirectorySecureBookmark];
        [sender setEnabled:false];
    }
}

@end
