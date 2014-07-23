//
//  SHRootController.m
//  SHLineGraphView
//
//  Created by SHAN UL HAQ on 23/3/14.
//  Copyright (c) 2014 grevolution. All rights reserved.
//

#import "SHRootController.h"
#import "SHLineGraphView.h"
#import "SHPlot.h"

@interface SHRootController ()<SHLineGraphViewDelegate>
@property (nonatomic, strong) NSArray *plottingValues;
@end

@implementation SHRootController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    //initate the graph view
    SHLineGraphView *_lineGraph = [[SHLineGraphView alloc] initWithFrame:CGRectMake(0, 0, 568, 320)];
    _lineGraph.delegate = self;
    _lineGraph.bezierMode = YES;

    _lineGraph.xAxisUnit = kSHLineGraphUnit_TimeInterval;
    _lineGraph.yAxisUnit = kSHLineGraphUnit_Integer;

    /**
     *  Array of dictionaries, where the key is the same as the one which you specified in the `xAxisValues` in `SHLineGraphView`,
     *  the value is the number which will determine the point location along the y-axis line. make sure the values are not
     *  greater than the `yAxisRange` specified in `SHLineGraphView`.
     */
    _plottingValues = @[
                              @6058,
                              @2000,
                              @2303,
                              @2200,
                              @1200,
                              @4500,
                              @5600,
                              @970,
                              @6507,
                              @1002,
                              @6709,
                              @2300
                              ];

    [_lineGraph reloadGraphWithAnimated:YES];

    [self.view addSubview:_lineGraph];
}

#pragma mark - SHLineGraphViewDelegate

-(NSString *)titleForLineGraph:(SHLineGraphView *)lineGraph
{
    return @"Line Graph Title";
}

-(SHPlotStyle *)lineGraph:(SHLineGraphView *)lineGraph styleForPlotIndex:(NSInteger)plotIndex
{
    SHPlotStyle *style = [[SHPlotStyle alloc] init];
//    style.fillColor = [UIColor clearColor];
    style.dotSize = 4.0;
    style.lineSize = 3.0;
    return style;
}

-(NSInteger)numberOfPlotsInLineGraph:(SHLineGraphView *)lineGraph
{
    return 1;
}

-(NSInteger)lineGraph:(SHLineGraphView *)lineGraph numberOfPointsInPlotIndex:(NSInteger)plotIndex
{
    return 2;
    return [_plottingValues count];
}

-(NSString *)lineGraph:(SHLineGraphView *)lineGraph titleForPlotIndex:(NSInteger)plotIndex
{
    return @"Segment";
}

-(double)lineGraph:(SHLineGraphView *)lineGraph XValueInPlotIndex:(NSInteger)plotIndex forPoint:(NSInteger)pointIndex
{
    if (pointIndex == 0) {
        return [[[NSDate date] dateByAddingTimeInterval:-1 * 60 * 60 * 24] timeIntervalSince1970];
    }
    else {
        return [[NSDate date] timeIntervalSince1970];
    }
//    NSDate *date = [NSDate date];
//    NSTimeInterval interval = -1 * 60 * 60 * 24 * ([_plottingValues count]-pointIndex);
//    return [[date dateByAddingTimeInterval:interval] timeIntervalSince1970];
//    return pointIndex + plotIndex;
}

-(double)lineGraph:(SHLineGraphView *)lineGraph YValueInPlotIndex:(NSInteger)plotIndex forPoint:(NSInteger)pointIndex
{
    return [[_plottingValues objectAtIndex:pointIndex] doubleValue] + plotIndex * 200;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotate
{
	return YES;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
	return UIInterfaceOrientationLandscapeLeft;
}


- (NSUInteger)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
}

@end
