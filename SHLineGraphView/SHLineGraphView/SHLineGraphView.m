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
#import "SHPlot.h"
#import "SHHoverLabel.h"
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

@property (nonatomic, assign) CGPoint touchLocation;
@property (nonatomic, assign) BOOL touched;

@property (nonatomic, strong) SHHoverLabel *hoverLabel;

@end

@implementation SHLineGraphView

#pragma mark - Initialization

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self loadDefaultTheme];
    }
    return self;
}

-(id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self loadDefaultTheme];
    }
    return self;
}

- (void)loadDefaultTheme {
    _labelColor = [UIColor colorWithRed:0.35 green:0.35 blue:0.35 alpha:1.0];
    _labelFont = [UIFont fontWithName:@"HelveticaNeue" size:10];
    _backgroundLineColor = [UIColor colorWithRed:0.48 green:0.48 blue:0.49 alpha:0.4];
    _titleColor = [UIColor blackColor];
    _titleFont = [UIFont fontWithName:@"HelveticaNeue" size:16];
    _hoverTextKeyFont = [UIFont fontWithName:@"HelveticaNeue" size:9];
    _hoverTextPlotFont = [UIFont fontWithName:@"HelveticaNeue" size:11];
    _hoverTextValueFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:11];
    _hoverTextColor = [UIColor blackColor];
}

#pragma mark - UIView

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_touched)
        return;
    _touched = YES;
    _touchLocation = [((UITouch *)[touches anyObject]) locationInView:self];
    [self reloadGraphWithAnimated:NO];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    _touchLocation = [((UITouch *)[touches anyObject]) locationInView:self];
    [self reloadGraphWithAnimated:NO];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesEndedOrCancelled:touches withEvent:event];
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesEndedOrCancelled:touches withEvent:event];
}

-(void)touchesEndedOrCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    _touched = NO;
    [self reloadGraphWithAnimated:NO];
}

#pragma mark - Public

- (void)reloadGraphWithAnimated:(BOOL)animated
{
    NSInteger numPlots = [_delegate numberOfPlotsInLineGraph:self];
    _plots = [[NSMutableArray alloc] initWithCapacity:numPlots];
    for (int plotIndex=0; plotIndex<numPlots; plotIndex++) {
        SHPlot *plot = [[SHPlot alloc] init];

        if ([_delegate respondsToSelector:@selector(lineGraph:styleForPlotIndex:)]) {
            plot.style = [_delegate lineGraph:self styleForPlotIndex:plotIndex];
            if (!plot.style) {
                plot.style = [[SHPlotStyle alloc] init];
            }
            [plot.style loadMissingDefaults];
        }
        NSMutableArray *dataPoints = [[NSMutableArray alloc] init];
        NSInteger numPoints = [_delegate lineGraph:self numberOfPointsInPlotIndex:plotIndex];
        for (int pointIndex=0; pointIndex<numPoints; pointIndex++) {

            SHDataPoint *dataPoint = [[SHDataPoint alloc] init];
            dataPoint.x = [_delegate lineGraph:self XValueInPlotIndex:plotIndex forPoint:pointIndex];
            dataPoint.y = [_delegate lineGraph:self YValueInPlotIndex:plotIndex forPoint:pointIndex];
            dataPoint.plot = plot;
            dataPoint.pointIndex = pointIndex;
            dataPoint.plotIndex = plotIndex;

            [dataPoints addObject:dataPoint];
        }
        plot.dataPoints = dataPoints;

        [_plots addObject:plot];
    }

    [[[self subviews] copy] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [[[self.layer sublayers] copy] makeObjectsPerformSelector:@selector(removeFromSuperlayer)];

    [self calculateAxesRanges];

    [self drawYLabels];
    [self drawXLabels];
    [self drawLines];
    [self drawTitle];

    [self drawPlotsWithAnimated:animated];
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

#pragma mark - Private

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

    CGPoint point = CGPointMake((x - _XAxisMin) * xScale / (_XAxisMax - _XAxisMin) + xOffset, (y - _YAxisMin) * yScale / (_YAxisMax - _YAxisMin) + yOffset);
    return point;
}

-(void)drawPlotsWithAnimated:(BOOL)animated
{
    for (SHPlot *plot in _plots) {
        [self drawPlot:plot animated:animated];
    }
}

- (void)drawPlot:(SHPlot *)plot animated:(BOOL)animated {

    if ([plot.dataPoints count] == 0)
        return;

    SHDataPoint *selectedDataPoint = nil;
    if (_touched) {
        selectedDataPoint = [self closestDataPointToLocation:_touchLocation];
    }

    CAShapeLayer *backgroundLayer = [CAShapeLayer layer];
    backgroundLayer.frame = self.bounds;
    backgroundLayer.fillColor = plot.style.fillColor.CGColor;
    backgroundLayer.backgroundColor = [UIColor clearColor].CGColor;
    [backgroundLayer setStrokeColor:[UIColor clearColor].CGColor];
    [backgroundLayer setLineWidth:plot.style.lineSize];

    CGMutablePathRef backgroundPath = CGPathCreateMutable();

    //
    CAShapeLayer *circleLayer = [CAShapeLayer layer];
    circleLayer.frame = self.bounds;
    circleLayer.fillColor = plot.style.strokeColor.CGColor;
    circleLayer.backgroundColor = [UIColor clearColor].CGColor;
    [circleLayer setStrokeColor:plot.style.strokeColor.CGColor];
    [circleLayer setLineWidth:(int)plot.style.dotSize];

    CGMutablePathRef circlePath = CGPathCreateMutable();

    //
    CAShapeLayer *graphLayer = [CAShapeLayer layer];
    graphLayer.frame = self.bounds;
    graphLayer.fillColor = [UIColor clearColor].CGColor;
    graphLayer.backgroundColor = [UIColor clearColor].CGColor;
    [graphLayer setStrokeColor:plot.style.strokeColor.CGColor];
    [graphLayer setLineWidth:(int)plot.style.lineSize];

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

        CGFloat dotsSize = plot.style.dotSize;
        if (dataPoint == selectedDataPoint) {
            dotsSize = 10.0;
        }
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
    if (animated) {
        [graphLayer addAnimation:animation forKey:@"strokeEnd"];
    }

    backgroundLayer.zPosition = 0;
    graphLayer.zPosition = 1;
    circleLayer.zPosition = 2;

    [self.layer addSublayer:graphLayer];
    [self.layer addSublayer:circleLayer];
    [self.layer addSublayer:backgroundLayer];

    if (selectedDataPoint) {
        [self showPopoverForDataPoint:selectedDataPoint];
    }

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

            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateStyle = NSDateFormatterLongStyle;
            formatter.timeStyle = NSDateFormatterMediumStyle;

            NSCalendar *calendar = [NSCalendar currentCalendar];
            NSDate *date = [calendar dateFromComponents:[calendar components:NSMonthCalendarUnit | NSYearCalendarUnit fromDate:minAbsoluteDate]];

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
    NSDateComponents *oneYearDelta = [[NSDateComponents alloc] init];
    oneYearDelta.year = 1;

    NSArray *componentArray = @[oneHourDelta, threeHourDelta, sixHourDelta,
                                twelveHourDelta, oneDayDelta, twoDayDelta,
                                oneWeekDelta, oneMonthDelta, oneYearDelta];
    NSCalendar *calendar = [NSCalendar currentCalendar];

    for (NSDateComponents *component in [componentArray reverseObjectEnumerator]) {
        NSDate *toDate = [calendar dateByAddingComponents:component toDate:fromDate options:0];
        NSTimeInterval deltaInterval = [toDate timeIntervalSinceDate:fromDate];
        if (deltaInterval < timeInterval)
            return component;
    }
    return oneHourDelta;
}

-(NSString *)textForDouble:(double)data withUnit:(SHLineGraphUnit)unit
{
    switch (unit) {
        case kSHLineGraphUnit_Decimal:
        {
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            formatter.locale = [NSLocale currentLocale];
            formatter.numberStyle = NSNumberFormatterDecimalStyle;
            formatter.usesGroupingSeparator = YES;
            formatter.roundingMode = NSNumberFormatterRoundHalfUp;
            formatter.minimumFractionDigits = 0;
            formatter.maximumFractionDigits = 2;
            return [formatter stringFromNumber:@(data)];
        }
        case kSHLineGraphUnit_Integer:
        {
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            formatter.locale = [NSLocale currentLocale];
            formatter.numberStyle = NSNumberFormatterDecimalStyle;
            formatter.usesGroupingSeparator = YES;
            formatter.roundingMode = NSNumberFormatterRoundFloor;
            formatter.maximumFractionDigits = 0;
            formatter.minimumFractionDigits = 0;
            return [formatter stringFromNumber:@(data)];
        }
        case kSHLineGraphUnit_TimeInterval:
        {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.locale = [NSLocale currentLocale];
            formatter.dateStyle = NSDateFormatterLongStyle;
            formatter.timeStyle = NSDateFormatterShortStyle;
            return [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:data]];
        }
        default:
            return nil;
    }
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
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.locale = [NSLocale currentLocale];
            if (components.hour) {
                NSString *dateFormat = [NSDateFormatter dateFormatFromTemplate:@"hh:mm" options:0 locale:[NSLocale currentLocale]];
                formatter.dateFormat = dateFormat;
                return [formatter stringFromDate:date];
            }
            else {
                NSString *dateFormat = [NSDateFormatter dateFormatFromTemplate:@"MMM dd" options:0 locale:[NSLocale currentLocale]];
                formatter.dateFormat = dateFormat;
                return [formatter stringFromDate:date];
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
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.locale = [NSLocale currentLocale];
            if (components.hour) {
                NSString *dateFormat = [NSDateFormatter dateFormatFromTemplate:@"hh:mm" options:0 locale:[NSLocale currentLocale]];
                formatter.dateFormat = dateFormat;
                return [formatter stringFromDate:date];
            }
            else {
                NSString *dateFormat = [NSDateFormatter dateFormatFromTemplate:@"MMM dd" options:0 locale:[NSLocale currentLocale]];
                formatter.dateFormat = dateFormat;
                return [formatter stringFromDate:date];
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
                            @{NSFontAttributeName: _labelFont,
                              NSParagraphStyleAttributeName: paragraphStyle}];
        CGRect labelRect = CGRectMake(xCenter - labelSize.width/2, yPos, labelSize.width, labelSize.height);

        UILabel *xAxisLabel = [[UILabel alloc] initWithFrame:labelRect];
        xAxisLabel.backgroundColor = [UIColor clearColor];
        xAxisLabel.font = _labelFont;
        xAxisLabel.textColor = _labelColor;
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
                            @{NSFontAttributeName: _labelFont,
                              NSParagraphStyleAttributeName: paragraphStyle}].height;
        CGRect labelRect = CGRectMake(xPos, yCenter - height/2, width, height);

        UILabel *yAxisLabel = [[UILabel alloc] initWithFrame:labelRect];
        yAxisLabel.backgroundColor = [UIColor clearColor];
        yAxisLabel.font = _labelFont;
        yAxisLabel.textColor = _labelColor;
        yAxisLabel.textAlignment = NSTextAlignmentRight;
        yAxisLabel.lineBreakMode = NSLineBreakByClipping;
        yAxisLabel.text = labelString;
        [self addSubview:yAxisLabel];
    }
}

-(void)drawTitle
{
    if (![_delegate respondsToSelector:@selector(titleForLineGraph:)] || ![[_delegate titleForLineGraph:self] length])
        return;

    NSString *titleString = [_delegate titleForLineGraph:self];
    CGFloat centerX = (self.bounds.size.width - LEFT_MARGIN_TO_LEAVE)/2;
    CGFloat centerY = TOP_MARGIN_TO_LEAVE/2;
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    CGSize titleSize = [titleString sizeWithAttributes:
                      @{NSFontAttributeName: _titleFont,
                        NSParagraphStyleAttributeName: paragraphStyle}];
    CGRect titleRect = CGRectMake(centerX - titleSize.width/2, centerY - titleSize.height/2, titleSize.width, titleSize.height);

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:titleRect];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.font = _titleFont;
    titleLabel.textColor = _titleColor;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.text = titleString;
    [self addSubview:titleLabel];
}

- (void)drawLines {

    NSArray *ticks = [self tickValuesForLabelMin:_YAxisMin max:_YAxisMax units:_yAxisUnit];

    CAShapeLayer *linesLayer = [CAShapeLayer layer];
    linesLayer.frame = self.bounds;
    linesLayer.fillColor = [UIColor clearColor].CGColor;
    linesLayer.backgroundColor = [UIColor clearColor].CGColor;
    linesLayer.strokeColor = _backgroundLineColor.CGColor;
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

-(SHDataPoint *)closestDataPointToLocation:(CGPoint)location
{
    CGFloat xTarget = location.x;
    CGFloat yTarget = location.y;
    NSMutableArray *candidates = [[NSMutableArray alloc] init];
    for (SHPlot *plot in _plots) {
        for (SHDataPoint *dataPoint in plot.dataPoints) {
            CGPoint dataPointLocation = [self dataPointToCoordinates:dataPoint];
            CGFloat dataPointX = dataPointLocation.x;
            CGFloat dataPointY = dataPointLocation.y;
            NSUInteger i;
            for (i=0; i<[candidates count]; i++) {
                CGFloat compareX = [self dataPointToCoordinates:candidates[i]].x;
                CGFloat compareY = [self dataPointToCoordinates:candidates[i]].y;

                CGFloat compareDist = fabsf(xTarget - compareX) + fabsf(yTarget - compareY);
                CGFloat dataPointDist = fabsf(xTarget - dataPointX) + fabsf(yTarget - dataPointY);
                if (dataPointDist < compareDist) {
                    break;
                }
            }
            [candidates insertObject:dataPoint atIndex:i];
        }
    }
    return [candidates firstObject];
}

-(void)showPopoverForDataPoint:(SHDataPoint *)dataPoint
{
    CGPoint point = [self dataPointToCoordinates:dataPoint];
    UIColor *plotColor = dataPoint.plot.style.strokeColor;

    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentLeft;
    
    NSDictionary *hoverTextXValueAttributes = @{
                                       NSFontAttributeName: _hoverTextKeyFont,
                                       NSForegroundColorAttributeName: _hoverTextColor,
                                       NSKernAttributeName: [NSNull null],
                                       NSParagraphStyleAttributeName: paragraphStyle};
    NSDictionary *hoverTextPlotAttributes = @{
                                     NSFontAttributeName: _hoverTextPlotFont,
                                     NSForegroundColorAttributeName:
                                         plotColor,
                                     NSKernAttributeName: [NSNull null],
                                     NSParagraphStyleAttributeName:
                                         paragraphStyle};
    NSDictionary *hoverTextSeparatorAttributes = @{
                                                NSFontAttributeName: _hoverTextPlotFont,
                                                NSForegroundColorAttributeName: _hoverTextColor,
                                                NSKernAttributeName: [NSNull null],
                                                NSParagraphStyleAttributeName: paragraphStyle};
    NSDictionary *hoverTextYValueAttributes = @{
                                                NSFontAttributeName: _hoverTextValueFont,
                                                NSForegroundColorAttributeName: _hoverTextColor,
                                                NSKernAttributeName: [NSNull null],
                                                NSParagraphStyleAttributeName: paragraphStyle};

    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];

    NSAttributedString *xValueString = [[NSAttributedString alloc] initWithString:[self textForDouble:dataPoint.x withUnit:_xAxisUnit] attributes:hoverTextXValueAttributes];
    [attributedString appendAttributedString:xValueString];

    NSAttributedString *newLineString = [[NSAttributedString alloc] initWithString:@"\n"];
    [attributedString appendAttributedString:newLineString];

    if ([_delegate respondsToSelector:@selector(lineGraph:titleForPlotIndex:)]) {
        NSAttributedString *plotTitleString = [[NSAttributedString alloc] initWithString:[_delegate lineGraph:self titleForPlotIndex:dataPoint.plotIndex] attributes:hoverTextPlotAttributes];
        [attributedString appendAttributedString:plotTitleString];

        NSAttributedString *separatorString = [[NSAttributedString alloc] initWithString:@": " attributes:hoverTextSeparatorAttributes];
        [attributedString appendAttributedString:separatorString];
    }

    NSAttributedString *yValueString = [[NSAttributedString alloc] initWithString:[self textForDouble:dataPoint.y withUnit:_yAxisUnit] attributes:hoverTextYValueAttributes];
    [attributedString appendAttributedString:yValueString];

    if (!_hoverLabel) {
        _hoverLabel = [SHHoverLabel hoverLabelAtPoint:_touchLocation inView:self withAttributedText:attributedString];
    }
    else {
        [_hoverLabel showAtPoint:point inView:self withAttributedText:attributedString];
    }
    _hoverLabel.borderColor = plotColor;
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

@end
