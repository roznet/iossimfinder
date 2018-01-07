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

#import <Cocoa/Cocoa.h>
#import "ISSimulatorOrganizer.h"
#import "ISSimulatorDataContainer.h"

extern NSString * kExecuteAction;

@interface ViewController : NSViewController<NSTableViewDelegate>

@property (nonatomic,retain) ISSimulatorOrganizer * organizer;
@property (weak) IBOutlet NSTableView *simTableView;
@property (weak) IBOutlet NSTableView *appTableView;

@property (weak) IBOutlet NSImageView *appIcon;
@property (weak) IBOutlet NSTextField *appName;
@property (weak) IBOutlet NSTextField *appVersion;
@property (weak) IBOutlet NSTextField *appBuild;
@property (weak) IBOutlet NSTextField *appIdentifier;
@property (weak) IBOutlet NSTextField *appUUID;

@property (weak) IBOutlet NSTextField *dataModifiedDate;
@property (weak) IBOutlet NSTextField *dataUUID;

@property (weak) IBOutlet NSTextField *deviceType;
@property (weak) IBOutlet NSTextField *deviceVersion;
@property (weak) IBOutlet NSTextField *deviceUUID;

@property (weak) IBOutlet NSTableView *downloadTableView;

@property (weak) IBOutlet NSButton *deviceTerminalButton;
@property (weak) IBOutlet NSButton *deviceFinderButton;
@property (weak) IBOutlet NSButton *deviceClipboardButton;

@property (weak) IBOutlet NSButton *appTerminalButton;
@property (weak) IBOutlet NSButton *appFinderButton;
@property (weak) IBOutlet NSButton *appClipboardButton;

@property (weak) IBOutlet NSButton *dataTerminalButton;
@property (weak) IBOutlet NSButton *dataFinderButton;
@property (weak) IBOutlet NSButton *dataClipboardButton;

@property (weak) IBOutlet NSButton *downloadTerminalButton;
@property (weak) IBOutlet NSButton *downloadClipboardButton;
@property (weak) IBOutlet NSButton *downloadFinderButton;

-(ISSimulatorDevice*)selectedDevice;
-(ISSimulatorApplication*)selectedApplication;
-(ISSimulatorDataContainer*)selectedDataContainer;
-(ISSimulatorDataContainer*)selectedDownloadDataContainer;


@end

