// SHLineGraphView.h
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

#import <UIKit/UIKit.h>
#import "SHPlot.h"

@class SHLineGraphView;

typedef NS_ENUM(NSInteger, SHLineGraphUnit) {
    kSHLineGraphUnit_Decimal,
    kSHLineGraphUnit_Integer,
    kSHLineGraphUnit_TimeInterval
};

@protocol SHLineGraphViewDelegate <NSObject>

@required
-(NSInteger)numberOfPlotsInLineGraph:(SHLineGraphView *)lineGraph;
-(NSInteger)lineGraph:(SHLineGraphView *)lineGraph numberOfPointsInPlotIndex:(NSInteger)plotIndex;
-(SHDataPoint *)lineGraph:(SHLineGraphView *)lineGraph dataPointInPlotIndex:(NSInteger)plotIndex ForPoint:(NSInteger)pointIndex;

@optional


-(NSString *)titleForPoint:(NSInteger)pointIndex inPlotIndex:(NSInteger)plotIndex;
-(NSString *)titleForPlotIndex:(NSInteger)plotIndex;

-(SHPlotStyle *)lineGraph:(SHLineGraphView *)lineGraph styleForPlotIndex:(NSInteger)plotIndex;

-(NSString *)lineGraph:(SHLineGraphView *)lineGraph customLabelForXAxisUnit:(double)xAxisUnit;
-(NSString *)lineGraph:(SHLineGraphView *)lineGraph customLabelForYAxisUnit:(double)yAxisUnit;

-(void)lineGraphDidBeginLoading:(SHLineGraphView *)lineGraph;
-(void)lineGraphDidFinishLoading:(SHLineGraphView *)lineGraph;

-(void)lineGraph:(SHLineGraphView *)lineGraph didStartTouchGraphWithClosestPoint:(NSInteger)pointIndex inPlotIndex:(NSInteger)plotIndex;
-(void)lineGraph:(SHLineGraphView *)lineGraph didReleaseTouchWithClosestPoint:(NSInteger)pointIndex inPlotIndex:(NSInteger)plotIndex;

@end

@interface SHLineGraphView : UIView

@property (nonatomic, strong) id<SHLineGraphViewDelegate> delegate;

@property (nonatomic, assign) SHLineGraphUnit xAxisUnit;
@property (nonatomic, assign) SHLineGraphUnit yAxisUnit;

@property (nonatomic, assign) BOOL bezierMode;

@property (nonatomic, strong) UIColor *labelColor;
@property (nonatomic, strong) UIFont *labelFont;
@property (nonatomic, strong) UIColor *backgroundLineColor;

/**
 *  this method is the actual method which starts the drawing of the graph and does all the magic. call this method when
 *  you are ready and want to show the graph.
 */
- (void)reloadGraph;

@end
