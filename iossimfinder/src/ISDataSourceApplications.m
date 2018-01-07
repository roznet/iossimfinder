//  MIT Licence
//
//  Created on 21/11/2014.
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

#import "ISDataSourceApplications.h"
#import "ISSimulatorDevice.h"
#import "ISSimulatorDataContainer.h"
#import "ISSimulatorApplication.h"

NSString * kNotifyApplicationChanged = @"kNotifyApplicationChanged";

@interface ISDataSourceApplications ()
@property (nonatomic,retain) ISSimulatorDevice * device;
@end

@implementation ISDataSourceApplications

+(ISDataSourceApplications*)dataSourceForDevice:(ISSimulatorDevice*)device{
    ISDataSourceApplications * rv = [[ISDataSourceApplications alloc] init];
    if (rv) {
        rv.device = device;
    }
    return rv;
}

-(BOOL)isSameDevice:(ISSimulatorDevice*)device{
    return [self.device isSameDevice:device];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return self.device.countOfApplications;
}

-(NSView*)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{

    // Get a new ViewCell
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];

    // Since this is a single-column table view, this would not be necessary.
    // But it's a good practice to do it in order by remember it when a table is multicolumn.
    if ([tableColumn.identifier isEqualToString:@"name"]) {
        NSString * name = [self.device applicationNameAtIndex:row];
        if (name) {
            cellView.textField.stringValue = name;
        }else{
            cellView.textField.stringValue = @"error";

        }
        NSImage * icon = [self.device applicationIconAtIndex:row];
        if (icon) {
            cellView.imageView.image = icon;
        }
    }else if ( [tableColumn.identifier isEqualToString:@"files"]){
        ISSimulatorApplication * app = [self.device applicationAtIndex:row];
        ISSimulatorDataContainer * container = [app lastDataContainer];
        if (container) {
            cellView.textField.stringValue = [NSString stringWithFormat:@"%d files (%@)",
                                              (int)container.fileCount,
                                              [container formatTotalFileSize]
                                              ];
        }else{
            cellView.textField.stringValue = @"";
        }
    }else{
        cellView.textField.stringValue = @"";
    }
    return cellView;
}

-(CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row{
    return 32.;
}

-(void)changeDevice:(ISSimulatorDevice*)newDevice{
    if (![self.device isSameDevice:newDevice]) {
        self.device = newDevice;

    }
}
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{

    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyApplicationChanged object:nil];
}

@end
