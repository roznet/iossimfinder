//  MIT Licence
//
//  Created on 25/11/2014.
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

#import "ISDataSourceDownloads.h"
#import "ISSimulatorDataContainer.h"

NSString * kNotifyDownloadChanged = @"NotifyDownloadChanged";

@interface ISDataSourceDownloads ()
@property (nonatomic,retain) NSArray * downloadContainers;
@end

@implementation ISDataSourceDownloads
+(ISDataSourceDownloads*)dataSourceFor:(ISSimulatorApplication*)app{
    ISDataSourceDownloads * rv = [[ISDataSourceDownloads alloc] init];
    if (rv) {
        rv.downloadContainers = [app downloadContainers];
    }
    return rv;
}

-(void)changeApplication:(ISSimulatorApplication*)app{
    self.downloadContainers = [app downloadContainers];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyDownloadChanged object:nil];
}


-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return self.downloadContainers.count;
}

-(NSView*)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{

    // Get a new ViewCell
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];

    // Since this is a single-column table view, this would not be necessary.
    // But it's a good practice to do it in order by remember it when a table is multicolumn.
    ISSimulatorDataContainer * container = [self.downloadContainers objectAtIndex:row];
    if ([tableColumn.identifier isEqualToString:@"date"]) {
        NSString * date = [NSString stringWithFormat:@"%@",container.lastModifiedDate ];
        cellView.textField.stringValue = date;
    }else if ( [tableColumn.identifier isEqualToString:@"info"]){
        cellView.textField.stringValue = [NSString stringWithFormat:@"%d files (%@)",
                                          (int)container.fileCount,
                                          [container formatTotalFileSize]
                                          ];
    }else if ( [tableColumn.identifier isEqualToString:@"version"]){
        cellView.textField.stringValue = container.appVersion;
    }else{
        cellView.textField.stringValue = @"";
    }
    return cellView;
}
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyDownloadChanged object:nil];
}

@end
