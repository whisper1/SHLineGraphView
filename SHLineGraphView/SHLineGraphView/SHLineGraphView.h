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

typedef NS_ENUM(NSInteger, SHLineGraphDotStyle) {
    kSHLineGraphDotStyle_Circle,
    kSHLineGraphDotStyle_Diamond,
    kSHLineGraphDotStyle_Square
};

typedef NS_ENUM(NSInteger, SHLineGraphLineStyle) {
    kSHLineGraphLineStyle_Solid,
    kSHLineGraphLineStyle_Dashed
};

@interface SHLineGraphPlotStyle : NSObject

@property (nonatomic, strong) UIColor *fillColor;
@property (nonatomic, strong) UIColor *lineColor;
@property (nonatomic, strong) UIColor *dotColor;
@property (nonatomic, assign) SHLineGraphDotStyle dotStyle;
@property (nonatomic, assign) SHLineGraphLineStyle lineStyle;
@property (nonatomic, assign) CGFloat dotSize;
@property (nonatomic, assign) CGFloat lineSize;

@end

@protocol SHLineGraphViewDelegate <NSObject>

@required
-(NSInteger)numberOfPlotsInLineGraph:(SHLineGraphView *)lineGraph;
-(NSInteger)lineGraph:(SHLineGraphView *)lineGraph numberOfPointsInPlotIndex:(NSInteger)plotIndex;
-(SHDataPoint *)lineGraph:(SHLineGraphView *)lineGraph dataPointInPlotIndex:(NSInteger)plotIndex ForPoint:(NSInteger)pointIndex;

@optional


-(NSString *)titleForPoint:(NSInteger)pointIndex inPlotIndex:(NSInteger)plotIndex;
-(NSString *)titleForPlotIndex:(NSInteger)plotIndex;

-(SHLineGraphPlotStyle *)lineGraph:(SHLineGraphView *)lineGraph styleForPlotIndex:(NSInteger)plotIndex;

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

/**
 *  y-axis values are calculated according to the yAxisRange passed. so you do not have to pass the explicit labels for 
 *  y-axis, but if you want to put any suffix to the calculated y-values, you can mention it here (e.g. K, M, Kg ...)
 */
@property (nonatomic, strong) NSString *yAxisSuffix;

/**
 *  theme attributes dictionary. you can specify graph theme releated attributes in this dictionary. if this property is 
 *  nil, then a default theme setting is applied to the graph.
 */
@property (nonatomic, strong) NSDictionary *themeAttributes;

/**
 *  this method is the actual method which starts the drawing of the graph and does all the magic. call this method when
 *  you are ready and want to show the graph.
 */
- (void)reloadGraph;


//===== Theme Attribute Keys =====

/**
 *  x-axis label color key. use this to define the x-axis color of the plot (UIColor*)
 */
UIKIT_EXTERN NSString *const kXAxisLabelColorKey;

/**
 *  x-axis label font key. use this to define the font of the x-axis labels. (UIFont*)
 */
UIKIT_EXTERN NSString *const kXAxisLabelFontKey;

/**
 *  y-axis label color key. use this to define the y-axis label color of the plot (UIColor*)
 */
UIKIT_EXTERN NSString *const kYAxisLabelColorKey;

/**
 *  y-axis label font key. use this to define the font of the y-axis labels. (UIFont*)
 */
UIKIT_EXTERN NSString *const kYAxisLabelFontKey;

/**
 *  y-axis label side margin key. use this to define the font of the y-axis labels side margin. the value will
 *  be equally divided into the both sides of the label. (NSNumber*)
 */
UIKIT_EXTERN NSString *const kYAxisLabelSideMarginsKey;

/**
 *  plot background line stroke color key. use this to define the stroke color of the background lines in plot (UIColor*)
 */
UIKIT_EXTERN NSString *const kPlotBackgroundLineColorKey;

/**
 *  size of the dot being drawing for each data point
 */
UIKIT_EXTERN NSString *const kDotSizeKey;

@end
