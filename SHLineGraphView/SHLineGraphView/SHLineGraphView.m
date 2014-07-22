// SHLineGraphView.m
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

#import "SHLineGraphView.h"
#import "PopoverView.h"
#import "SHPlot.h"
#import <math.h>
#import <objc/runtime.h>

#define BOTTOM_MARGIN_TO_LEAVE 30.0
#define TOP_MARGIN_TO_LEAVE 30.0
#define LEFT_MARGIN_TO_LEAVE 35.0
#define INTERVAL_COUNT 6
#define LEFT_PADDING 15.0
#define RIGHT_PADDING 15.0

#define kAssociatedPlotObject @"kAssociatedPlotObject"

@interface SHLineGraphView ()

@property (nonatomic, strong) NSMutableArray *plots;

@property (nonatomic, strong) NSArray *xAxisLabels;

@property (nonatomic, assign) double XAxisMin;
@property (nonatomic, assign) double XAxisMax;
@property (nonatomic, assign) double YAxisMin;
@property (nonatomic, assign) double YAxisMax;

@end

@implementation SHLineGraphView

- (instancetype)init {
    if((self = [super init])) {
        [self loadDefaultTheme];
    }
    return self;
}

- (void)awakeFromNib
{
    [self loadDefaultTheme];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self loadDefaultTheme];
    }
    return self;
}

- (void)loadDefaultTheme {
    _themeAttributes = @{
                         kXAxisLabelColorKey : [UIColor colorWithRed:0.48 green:0.48 blue:0.49 alpha:0.4],
                         kXAxisLabelFontKey : [UIFont fontWithName:@"HelveticaNeue-Light" size:10],
                         kYAxisLabelColorKey : [UIColor colorWithRed:0.48 green:0.48 blue:0.49 alpha:0.4],
                         kYAxisLabelFontKey : [UIFont fontWithName:@"HelveticaNeue-Light" size:10],
                         kYAxisLabelSideMarginsKey : @10,
                         kPlotBackgroundLineColorKey : [UIColor colorWithRed:0.48 green:0.48 blue:0.49 alpha:0.4],
                         kDotSizeKey : @10.0
                         };
}

- (void)reloadGraph
{
    NSInteger numPlots = [_delegate numberOfPlotsInLineGraph:self];
    _plots = [[NSMutableArray alloc] initWithCapacity:numPlots];
    for (int plotIndex=0; plotIndex<numPlots; plotIndex++) {
        SHPlot *plot = [[SHPlot alloc] init];

        if ([_delegate respondsToSelector:@selector(lineGraph:styleForPlotIndex:)]) {
            SHLineGraphPlotStyle *plotStyle = [_delegate lineGraph:self styleForPlotIndex:plotIndex];
            plot.plotThemeAttributes = @{
                                         kPlotFillColorKey: plotStyle.fillColor,
                                         kPlotStrokeWidthKey: @(plotStyle.lineSize),
                                         kPlotStrokeColorKey: plotStyle.lineColor,
                                         kPlotPointValueFontKey: [UIFont fontWithName:@"HelveticaNeue-Light" size:18]
                                         };
        }
        NSMutableArray *dataPoints = [[NSMutableArray alloc] init];
        NSInteger numPoints = [_delegate lineGraph:self numberOfPointsInPlotIndex:plotIndex];
        for (int pointIndex=0; pointIndex<numPoints; pointIndex++) {

            SHDataPoint *dataPoint = [_delegate lineGraph:self dataPointInPlotIndex:plotIndex ForPoint:pointIndex];
            [dataPoints addObject:dataPoint];
        }
        plot.dataPoints = dataPoints;

        [_plots addObject:plot];
    }

    [self calculateAxesRanges];

    [self drawYLabels];
    [self drawXLabels];
    [self drawLines];

    for(SHPlot *plot in _plots) {
        [self drawPlot:plot];
    }
}

-(void)calculateAxesRanges
{
    _YAxisMin = 0.0;
    if ([_plots count] && [((SHPlot *)_plots[0]).dataPoints count] && ((SHPlot *)_plots[0]).dataPoints[0]) {
        SHDataPoint *point = ((SHPlot *)_plots[0]).dataPoints[0];
        _XAxisMin = point.x;
        _XAxisMax = point.x;
        _YAxisMax = point.y;
    }
    for (SHPlot *plot in _plots) {
        for (SHDataPoint *point in plot.dataPoints) {
            if (_XAxisMin > point.x)
                _XAxisMin = point.x;
            if (_XAxisMax < point.x)
                _XAxisMax = point.x;
            if (_YAxisMax < point.y)
                _YAxisMax = point.y;
        }
    }
}

#pragma mark - Actual Plot Drawing Methods

-(CGPoint)dataPointToCoordinates:(SHDataPoint *)dataPoint
{
    return [self dataToCoordinates:dataPoint.x y:dataPoint.y];
}

-(CGPoint)dataToCoordinates:(double)x y:(double)y
{
    CGFloat xOffset = LEFT_PADDING + LEFT_MARGIN_TO_LEAVE;
    CGFloat xScale = self.bounds.size.width - LEFT_PADDING - LEFT_MARGIN_TO_LEAVE - RIGHT_PADDING;
    CGFloat yOffset = self.bounds.size.height - BOTTOM_MARGIN_TO_LEAVE;
    CGFloat yScale = -(self.bounds.size.height - BOTTOM_MARGIN_TO_LEAVE - TOP_MARGIN_TO_LEAVE);

    if (_XAxisMax == 0 || _YAxisMax == 0)
        return CGPointMake(xOffset, yOffset);

    CGPoint point = CGPointMake(x * xScale / (_XAxisMax - _XAxisMin) + xOffset, y * yScale / (_YAxisMax - _YAxisMin) + yOffset);
    return point;
}

- (void)drawPlot:(SHPlot *)plot {

    if ([plot.dataPoints count] == 0)
        return;

    NSDictionary *theme = plot.plotThemeAttributes;

    CAShapeLayer *backgroundLayer = [CAShapeLayer layer];
    backgroundLayer.frame = self.bounds;
    backgroundLayer.fillColor = ((UIColor *)theme[kPlotFillColorKey]).CGColor;
    backgroundLayer.backgroundColor = [UIColor clearColor].CGColor;
    [backgroundLayer setStrokeColor:[UIColor clearColor].CGColor];
    [backgroundLayer setLineWidth:((NSNumber *)theme[kPlotStrokeWidthKey]).intValue];

    CGMutablePathRef backgroundPath = CGPathCreateMutable();

    //
    CAShapeLayer *circleLayer = [CAShapeLayer layer];
    circleLayer.frame = self.bounds;
    circleLayer.fillColor = ((UIColor *)theme[kPlotPointFillColorKey]).CGColor;
    circleLayer.backgroundColor = [UIColor clearColor].CGColor;
    [circleLayer setStrokeColor:((UIColor *)theme[kPlotPointFillColorKey]).CGColor];
    [circleLayer setLineWidth:((NSNumber *)theme[kPlotStrokeWidthKey]).intValue];

    CGMutablePathRef circlePath = CGPathCreateMutable();

    //
    CAShapeLayer *graphLayer = [CAShapeLayer layer];
    graphLayer.frame = self.bounds;
    graphLayer.fillColor = [UIColor clearColor].CGColor;
    graphLayer.backgroundColor = [UIColor clearColor].CGColor;
    [graphLayer setStrokeColor:((UIColor *)theme[kPlotStrokeColorKey]).CGColor];
    [graphLayer setLineWidth:((NSNumber *)theme[kPlotStrokeWidthKey]).intValue];

    CGMutablePathRef graphPath = CGPathCreateMutable();

    CGPoint firstPoint = [self dataPointToCoordinates:plot.dataPoints[0]];

    CGPathMoveToPoint(graphPath, NULL, firstPoint.x, firstPoint.y);
    CGPathMoveToPoint(backgroundPath, NULL, LEFT_MARGIN_TO_LEAVE, firstPoint.y);

    CGPoint prevPrevPoint = firstPoint;
    CGPoint prevPoint = firstPoint;
    CGPoint nextPoint = firstPoint;

    for (int i=0; i<[plot.dataPoints count]; i++) {

        SHDataPoint *dataPoint = plot.dataPoints[i];

        CGPoint curPoint = [self dataPointToCoordinates:dataPoint];
        nextPoint = (i+1 == [plot.dataPoints count])? curPoint : [self dataPointToCoordinates:plot.dataPoints[i+1]];

        CGPoint controlPoint1 = CGPointMake(prevPoint.x + (curPoint.x - prevPoint.x)/3, prevPoint.y - (prevPoint.y - curPoint.y)/3 - (prevPrevPoint.y - prevPoint.y)*0.3);
        CGPoint controlPoint2 = CGPointMake(prevPoint.x + 2*(curPoint.x - prevPoint.x)/3, (prevPoint.y - 2*(prevPoint.y - curPoint.y)/3) + (curPoint.y - nextPoint.y)*0.3);

        if (_bezierMode && i != 0) {
            CGPathAddCurveToPoint(graphPath, NULL, controlPoint1.x, controlPoint1.y, controlPoint2.x, controlPoint2.y, curPoint.x, curPoint.y);
            CGPathAddCurveToPoint(backgroundPath, NULL, controlPoint1.x, controlPoint1.y, controlPoint2.x, controlPoint2.y, curPoint.x, curPoint.y);
        }
        else {
            CGPathAddLineToPoint(graphPath, NULL, curPoint.x, curPoint.y);
            CGPathAddLineToPoint(backgroundPath, NULL, curPoint.x, curPoint.y);
        }

        CGFloat dotsSize = [_themeAttributes[kDotSizeKey] floatValue];
        CGPathAddEllipseInRect(circlePath, NULL, CGRectMake(curPoint.x - dotsSize/2, curPoint.y-dotsSize/2, dotsSize, dotsSize));

        prevPrevPoint = prevPoint;
        prevPoint = curPoint;
    }

    CGPoint lastPoint = [self dataPointToCoordinates:[plot.dataPoints lastObject]];
    CGPathAddLineToPoint(backgroundPath, NULL, self.bounds.size.width, lastPoint.y);

    CGPathAddLineToPoint(backgroundPath, NULL, self.bounds.size.width, self.bounds.size.height - BOTTOM_MARGIN_TO_LEAVE);
    CGPathAddLineToPoint(backgroundPath, NULL, LEFT_MARGIN_TO_LEAVE, self.bounds.size.height - BOTTOM_MARGIN_TO_LEAVE);

    CGPathCloseSubpath(backgroundPath);

    backgroundLayer.path = backgroundPath;
    graphLayer.path = graphPath;
    circleLayer.path = circlePath;

    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];

    animation.duration = 1;
    animation.fromValue = @(0.0);
    animation.toValue = @(1.0);
    [graphLayer addAnimation:animation forKey:@"strokeEnd"];

    backgroundLayer.zPosition = 0;
    graphLayer.zPosition = 1;
    circleLayer.zPosition = 2;

    [self.layer addSublayer:graphLayer];
    [self.layer addSublayer:circleLayer];
    [self.layer addSublayer:backgroundLayer];

//	NSUInteger count2 = _xAxisValues.count;
//	for(int i=0; i< count2; i++){
//		CGPoint point = plot.xPoints[i];
//		UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
//
//		btn.backgroundColor = [UIColor clearColor];
//		btn.tag = i;
//		btn.frame = CGRectMake(point.x - 20, point.y - 20, 40, 40);
//		[btn addTarget:self action:@selector(clicked:) forControlEvents:UIControlEventTouchUpInside];
//		objc_setAssociatedObject(btn, kAssociatedPlotObject, plot, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
//
//        [self addSubview:btn];
//	}
}

-(NSArray *)tickValuesForLabelMin:(double)min max:(double)max units:(SHLineGraphUnit)unit
{
    NSMutableArray *ticks = [[NSMutableArray alloc] init];
    switch (unit) {
        case kSHLineGraphUnit_Decimal:
        {
            double delta = (max - min) / INTERVAL_COUNT;
            for (double val = min; val < max; val += delta) {
                [ticks addObject:@(val)];
            }
            [ticks addObject:@(max)];
            break;
        }
        case kSHLineGraphUnit_Integer:
        {
            long longMin = (long)min;
            long longMax = (long)max;
            long interval = (longMax - longMin) / INTERVAL_COUNT;

            long prettyInterval = [self deltaForIntegerRange:interval];
            long tick = 0;
            while (tick < longMax) {
                if (tick >= longMin) {
                    [ticks addObject:@(tick)];
                }
                tick += prettyInterval;
            }
            [ticks addObject:@(tick)];
            break;
        }
        case kSHLineGraphUnit_TimeInterval:
        {
            NSTimeInterval absoluteRange = max - min;
            NSDate *minAbsoluteDate = [NSDate dateWithTimeIntervalSince1970:min];
            NSDate *maxAbsoluteDate = [NSDate dateWithTimeIntervalSince1970:max];

            NSTimeInterval absoluteInterval = absoluteRange / INTERVAL_COUNT;

            NSCalendar *calendar = [NSCalendar currentCalendar];
            NSDate *date = [calendar dateFromComponents:[calendar components:NSMonthCalendarUnit fromDate:minAbsoluteDate]];

            NSDateComponents *deltaDateComponents = [self deltaDateComponentsForTimeInterval:absoluteInterval fromDate:date];

            while ([maxAbsoluteDate timeIntervalSinceDate:date] >= 0.0) {
                if ([date timeIntervalSinceDate:minAbsoluteDate] >= 0.0) {
                    [ticks addObject:@([date timeIntervalSince1970])];
                }
                date = [calendar dateByAddingComponents:deltaDateComponents toDate:date options:0];
            }
            [ticks addObject:@([date timeIntervalSince1970])];
            break;
        }
        default:
            break;
    }
    return ticks;
}

-(long)deltaForIntegerRange:(long)integerRange
{
    NSArray *deltaArray = @[@(1), @(5), @(10), @(25), @(50),
                            @(100), @(250), @(500), @(1000),
                            @(2500),       @(5000),      @(10000),
                            @(25000L),      @(50000L),     @(100000L),
                            @(250000L),     @(500000L),    @(1000000L),
                            @(2500000L),    @(5000000L),   @(10000000L),
                            @(25000000L),   @(50000000L),  @(100000000L)];
    for (NSNumber *number in [deltaArray reverseObjectEnumerator]) {
        if ([number longValue] < integerRange) {
            return [number longValue];
        }
    }
    return [[deltaArray firstObject] longValue];
}

-(NSDateComponents *)deltaDateComponentsForTimeInterval:(NSTimeInterval)timeInterval fromDate:(NSDate *)fromDate
{
    NSDateComponents *oneHourDelta = [[NSDateComponents alloc] init];
    oneHourDelta.hour = 1;
    NSDateComponents *threeHourDelta = [[NSDateComponents alloc] init];
    threeHourDelta.hour = 3;
    NSDateComponents *sixHourDelta = [[NSDateComponents alloc] init];
    sixHourDelta.hour = 6;
    NSDateComponents *twelveHourDelta = [[NSDateComponents alloc] init];
    twelveHourDelta.hour = 12;
    NSDateComponents *oneDayDelta = [[NSDateComponents alloc] init];
    oneDayDelta.day = 1;
    NSDateComponents *twoDayDelta = [[NSDateComponents alloc] init];
    twoDayDelta.day = 2;
    NSDateComponents *oneWeekDelta = [[NSDateComponents alloc] init];
    oneWeekDelta.week = 1;
    NSDateComponents *oneMonthDelta = [[NSDateComponents alloc] init];
    oneMonthDelta.month = 1;

    NSArray *componentArray = @[oneHourDelta, threeHourDelta, sixHourDelta,
                                twelveHourDelta, oneDayDelta, twoDayDelta,
                                oneWeekDelta, oneMonthDelta];
    NSCalendar *calendar = [NSCalendar currentCalendar];

    for (NSDateComponents *component in [componentArray reverseObjectEnumerator]) {
        NSDate *toDate = [calendar dateByAddingComponents:component toDate:fromDate options:0];
        NSTimeInterval deltaInterval = [toDate timeIntervalSinceDate:fromDate];
        if (deltaInterval < timeInterval)
            return component;
    }
    return oneHourDelta;
}

-(NSString *)textForXAxisUnit:(double)xAxisUnit
{
    if ([_delegate respondsToSelector:@selector(lineGraph:customLabelForXAxisUnit:)]) {
        return [_delegate lineGraph:self customLabelForXAxisUnit:xAxisUnit];
    }
    switch (_xAxisUnit) {
        case kSHLineGraphUnit_Decimal:
        {
            if (_XAxisMax > 10000) {
                return [NSString stringWithFormat:@"%2.0fk", xAxisUnit/1000];
            }
            if (_XAxisMax > 5000) {
                return [NSString stringWithFormat:@"%2.1fk", xAxisUnit/1000];
            }
            return [NSString stringWithFormat:@"%2.1f", xAxisUnit];
        }
        case kSHLineGraphUnit_Integer:
        {
            if (_XAxisMax > 10000) {
                return [NSString stringWithFormat:@"%2.0fk", xAxisUnit/1000];
            }
            if (_XAxisMax > 5000) {
                return [NSString stringWithFormat:@"%2.1fk", xAxisUnit/1000];
            }
            return [NSString stringWithFormat:@"%2.0f", xAxisUnit];
            break;
        }
        case kSHLineGraphUnit_TimeInterval:
        {
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:xAxisUnit];
            NSCalendar *calendar = [NSCalendar currentCalendar];
            NSDateComponents *components = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit fromDate:date];
            if (components.hour) {
                return [NSDateFormatter dateFormatFromTemplate:@"hh:mm" options:0 locale:[NSLocale currentLocale]];
            }
            else {
                return [NSDateFormatter dateFormatFromTemplate:@"MMM dd" options:0 locale:[NSLocale currentLocale]];
            }
        }
        default:
            return nil;
    }
}

-(NSString *)textForYAxisUnit:(double)yAxisUnit
{
    if ([_delegate respondsToSelector:@selector(lineGraph:customLabelForYAxisUnit:)]) {
        return [_delegate lineGraph:self customLabelForXAxisUnit:yAxisUnit];
    }
    switch (_yAxisUnit) {
        case kSHLineGraphUnit_Decimal:
        {
            if (_YAxisMax > 100000) {
                return [NSString stringWithFormat:@"%2.0fk", yAxisUnit/1000];
            }
            if (_YAxisMax > 5000) {
                return [NSString stringWithFormat:@"%2.1fk", yAxisUnit/1000];
            }
            return [NSString stringWithFormat:@"%2.1f", yAxisUnit];
        }
        case kSHLineGraphUnit_Integer:
        {
            if (_YAxisMax > 100000) {
                return [NSString stringWithFormat:@"%2.0fk", yAxisUnit/1000];
            }
            if (_YAxisMax > 5000) {
                return [NSString stringWithFormat:@"%2.1fk", yAxisUnit/1000];
            }
            return [NSString stringWithFormat:@"%2.0f", yAxisUnit];
        }
        case kSHLineGraphUnit_TimeInterval:
        {
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:yAxisUnit];
            NSCalendar *calendar = [NSCalendar currentCalendar];
            NSDateComponents *components = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit fromDate:date];
            if (components.hour) {
                return [NSDateFormatter dateFormatFromTemplate:@"hh:mm" options:0 locale:[NSLocale currentLocale]];
            }
            else {
                return [NSDateFormatter dateFormatFromTemplate:@"MMM dd" options:0 locale:[NSLocale currentLocale]];
            }
        }
        default:
            return nil;
    }
}

- (void)drawXLabels {

    NSArray *xAxisTicks = [self tickValuesForLabelMin:_XAxisMin max:_XAxisMax units:_xAxisUnit];

    for (NSNumber *tickNumber in xAxisTicks) {
        double tick = [tickNumber doubleValue];

        CGFloat xCenter = [self dataToCoordinates:tick y:0.0].x;
        CGFloat yPos = self.bounds.size.height - BOTTOM_MARGIN_TO_LEAVE+5;
        NSString *labelString = [self textForXAxisUnit:tick];
        NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyle.alignment = NSTextAlignmentCenter;
        paragraphStyle.lineBreakMode = NSLineBreakByClipping;
        CGSize labelSize = [labelString sizeWithAttributes:
                            @{NSFontAttributeName: _themeAttributes[kXAxisLabelFontKey],
                              NSParagraphStyleAttributeName: paragraphStyle}];
        CGRect labelRect = CGRectMake(xCenter - labelSize.width/2, yPos, labelSize.width, labelSize.height);

        UILabel *xAxisLabel = [[UILabel alloc] initWithFrame:labelRect];
        xAxisLabel.backgroundColor = [UIColor clearColor];
        xAxisLabel.font = (UIFont *)_themeAttributes[kXAxisLabelFontKey];
        xAxisLabel.textColor = (UIColor *)_themeAttributes[kXAxisLabelColorKey];
        xAxisLabel.textAlignment = NSTextAlignmentCenter;
        xAxisLabel.lineBreakMode = NSLineBreakByClipping;
        xAxisLabel.text = labelString;
        [self addSubview:xAxisLabel];
    }
}

- (void)drawYLabels {

    NSArray *yAxisTicks = [self tickValuesForLabelMin:_YAxisMin max:_YAxisMax units:_yAxisUnit];

    for (NSNumber *tickNumber in yAxisTicks) {
        double tick = [tickNumber doubleValue];

        CGFloat yCenter = [self dataToCoordinates:0.0 y:tick].y;
        CGFloat xPos = 0.0;
        CGFloat width = LEFT_MARGIN_TO_LEAVE-5;
        NSString *labelString = [self textForYAxisUnit:tick];
        NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyle.alignment = NSTextAlignmentRight;
        paragraphStyle.lineBreakMode = NSLineBreakByClipping;
        CGFloat height = [labelString sizeWithAttributes:
                            @{NSFontAttributeName: _themeAttributes[kYAxisLabelFontKey],
                              NSParagraphStyleAttributeName: paragraphStyle}].height;
        CGRect labelRect = CGRectMake(xPos, yCenter - height/2, width, height);

        UILabel *yAxisLabel = [[UILabel alloc] initWithFrame:labelRect];
        yAxisLabel.backgroundColor = [UIColor clearColor];
        yAxisLabel.font = (UIFont *)_themeAttributes[kYAxisLabelFontKey];
        yAxisLabel.textColor = (UIColor *)_themeAttributes[kYAxisLabelColorKey];
        yAxisLabel.textAlignment = NSTextAlignmentRight;
        yAxisLabel.lineBreakMode = NSLineBreakByClipping;
        yAxisLabel.text = labelString;
        [self addSubview:yAxisLabel];
    }
}

- (void)drawLines {

    NSArray *ticks = [self tickValuesForLabelMin:_YAxisMin max:_YAxisMax units:_yAxisUnit];

    CAShapeLayer *linesLayer = [CAShapeLayer layer];
    linesLayer.frame = self.bounds;
    linesLayer.fillColor = [UIColor clearColor].CGColor;
    linesLayer.backgroundColor = [UIColor clearColor].CGColor;
    linesLayer.strokeColor = ((UIColor *)_themeAttributes[kPlotBackgroundLineColorKey]).CGColor;
    linesLayer.lineWidth = 1;

    CGMutablePathRef linesPath = CGPathCreateMutable();

    for (NSNumber *tickNumber in ticks) {

        double tick = [tickNumber doubleValue];
        CGFloat y = [self dataToCoordinates:0.0 y:tick].y;

        CGPoint currentLinePoint = CGPointMake(LEFT_MARGIN_TO_LEAVE, y);

        CGPathMoveToPoint(linesPath, NULL, currentLinePoint.x, currentLinePoint.y);
        CGPathAddLineToPoint(linesPath, NULL, currentLinePoint.x + self.bounds.size.width - LEFT_MARGIN_TO_LEAVE, currentLinePoint.y);
    }

    linesLayer.path = linesPath;
    [self.layer addSublayer:linesLayer];
}

#pragma mark - UIButton event methods

//- (void)clicked:(id)sender
//{
//	@try {
//		UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120, 30)];
//		lbl.backgroundColor = [UIColor clearColor];
//        UIButton *btn = (UIButton *)sender;
//		NSUInteger tag = btn.tag;
//
//        SHPlot *_plot = objc_getAssociatedObject(btn, kAssociatedPlotObject);
//		NSString *text = [_plot.plottingPointsLabels objectAtIndex:tag];
//
//		lbl.text = text;
//		lbl.textColor = [UIColor whiteColor];
//		lbl.textAlignment = NSTextAlignmentCenter;
//		lbl.font = (UIFont *)_plot.plotThemeAttributes[kPlotPointValueFontKey];
//		[lbl sizeToFit];
//		lbl.frame = CGRectMake(0, 0, lbl.frame.size.width + 5, lbl.frame.size.height);
//
//		CGPoint point =((UIButton *)sender).center;
//		point.y -= 15;
//
//		dispatch_async(dispatch_get_main_queue(), ^{
//			[PopoverView showPopoverAtPoint:point
//                                     inView:self
//                            withContentView:lbl
//                                   delegate:nil];
//		});
//	}
//	@catch (NSException *exception) {
//		NSLog(@"plotting label is not available for this point");
//	}
//}

#pragma mark - Theme Key Extern Keys

NSString *const kXAxisLabelColorKey         = @"kXAxisLabelColorKey";
NSString *const kXAxisLabelFontKey          = @"kXAxisLabelFontKey";
NSString *const kYAxisLabelColorKey         = @"kYAxisLabelColorKey";
NSString *const kYAxisLabelFontKey          = @"kYAxisLabelFontKey";
NSString *const kYAxisLabelSideMarginsKey   = @"kYAxisLabelSideMarginsKey";
NSString *const kPlotBackgroundLineColorKey = @"kPlotBackgroundLineColorKey";
NSString *const kDotSizeKey                 = @"kDotSizeKey";

@end
