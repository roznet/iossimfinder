//  MIT Licence
//
//  Created on 18/11/2014.
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

#import "RZTaskRunner.h"

@interface RZTaskRunner ()
@property (nonatomic,retain) NSTask * task;
@property (nonatomic,retain) NSPipe * pipe;
@property (nonatomic,retain) NSString * standardOutput;

@end

@implementation RZTaskRunner
+(RZTaskRunner*)runTask:(NSString*)command args:(NSArray*)args{
    RZTaskRunner * rv = [[RZTaskRunner alloc] init];
    if (rv) {
        rv.task = [[NSTask alloc] init];
        rv.task.launchPath = command;
        rv.task.arguments = args;
        rv.pipe = [NSPipe pipe];
        rv.task.standardOutput = rv.pipe;

        [rv.task launch];
        NSData * data = [[rv.pipe fileHandleForReading] readDataToEndOfFile];
        rv.standardOutput = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return rv;
}
@end
