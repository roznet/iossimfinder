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

#import "ISDataSourceDevices.h"

NSString * kNotifyDeviceChanged = @"kNotifyDeviceChanged";

@interface ISDataSourceDevices ()
@property (nonatomic,retain) ISSimulatorOrganizer * organizer;
@end
@implementation ISDataSourceDevices

+(ISDataSourceDevices*)dataSourceForOrganizer:(ISSimulatorOrganizer*)organizer{
    ISDataSourceDevices * rv = [[ISDataSourceDevices alloc] init];
    if (rv) {
        rv.organizer = organizer;
    }
    return rv;
}
-(void)changeOrganizer:(ISSimulatorOrganizer*)organizer{
    self.organizer = organizer;
}
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return self.organizer.count;
}

-(NSView*)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{

    // Get a new ViewCell
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];

    // Since this is a single-column table view, this would not be necessary.
    // But it's a good practice to do it in order by remember it when a table is multicolumn.
    if ([tableColumn.identifier isEqualToString:@"name"]) {
        cellView.textField.stringValue = [self.organizer deviceNameAtIndex:row];
        if ([[self.organizer deviceAtIndex:row] isIphone]) {
            cellView.imageView.image = [NSImage imageNamed:@"iphone"];
        }else{
            cellView.imageView.image = [NSImage imageNamed:@"ipad"];
        }
    }else if([tableColumn.identifier isEqualToString:@"applications"]){
        NSUInteger n = [[self.organizer deviceAtIndex:row] countOfApplications];
        if (n>0) {
            cellView.textField.stringValue = [NSString stringWithFormat:@"%d applications", (int)[[self.organizer deviceAtIndex:row] countOfApplications]];
        }else{
            cellView.textField.stringValue = @"";

        }
    }else if([tableColumn.identifier isEqualToString:@"runtime"]){
        cellView.textField.stringValue = [[self.organizer  deviceAtIndex:row] deviceRunTime];
    }
    return cellView;
}
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyDeviceChanged object:nil];
}

-(CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row{
    return 20.;
}

@end
