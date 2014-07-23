// SHPlot.m
//
// Copyright (c) 2014 Shan Ul Haq (http://grevolution.me)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#import "SHPlot.h"

@implementation SHDataPoint

-(id)init
{
    if (self = [super init]) {

    }
    return self;
}

@end

@implementation SHPlotStyle

-(id)init
{
    if (self = [super init]) {
        [self loadMissingDefaults];
    }
    return self;
}

-(void)loadMissingDefaults
{
    if (!_fillColor)
        _fillColor = [UIColor colorWithRed:0.47 green:0.75 blue:0.78 alpha:0.5];
    if (!_strokeColor)
        _strokeColor = [UIColor colorWithRed:0.18 green:0.36 blue:0.41 alpha:1];
    if (!_dotSize)
        _dotSize = 5.0;
    if (!_lineSize)
        _lineSize = 2.0;
}

@end

@implementation SHPlot

- (instancetype)init {
    if((self = [super init])) {
        _style = [[SHPlotStyle alloc] init];
    }
    return self;
}

@end