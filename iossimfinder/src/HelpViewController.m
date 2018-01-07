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

#import "HelpViewController.h"
#import "ISAppGlobal.h"
@interface HelpViewController ()
@property (weak) IBOutlet NSSegmentedControl *languageChoice;
@property (weak) IBOutlet NSButton *saveButton;
@property (nonatomic,assign) BOOL showSwift;
@end

@implementation HelpViewController
- (IBAction)languageChanged:(NSSegmentedControl*)sender {
    if (sender.selectedSegment == 1) {
        self.showSwift = true;
    }else{
        self.showSwift = false;
    }
    [self updateText];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.

    self.showSwift = false;
    [self updateText];
}

-(void)updateText{

    NSAttributedString * str = nil;
    NSString * buttonText = nil;
    if (self.showSwift) {
        NSString * rtffile = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"helpswift.rtf"];
        str = [[NSAttributedString alloc] initWithRTF:[NSData dataWithContentsOfFile:rtffile] documentAttributes:nil];
        buttonText = NSLocalizedString(@"Save Swift", @"Save Button");
    }else{
        NSString * rtffile = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"helpdialog.rtf"];
        str = [[NSAttributedString alloc] initWithRTF:[NSData dataWithContentsOfFile:rtffile] documentAttributes:nil];
        buttonText = NSLocalizedString(@"Save Header", @"Save Button");
    }
    self.saveButton.title = buttonText;
    self.textView.attributedStringValue = str;
}

- (IBAction)saveHeader:(id)sender {
    if (self.showSwift) {
        [ISAppGlobal saveSwiftFile];
    }else{
        [ISAppGlobal saveHeaderFile];
    }
}

@end
