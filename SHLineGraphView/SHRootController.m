//
//  SHRootController.m
//  SHLineGraphView
//
//  Created by SHAN UL HAQ on 23/3/14.
//  Copyright (c) 2014 grevolution. All rights reserved.
//

#import "SHRootController.h"
#import "SHLineGraphView.h"
#import "SHPlotStyle.h"

@interface SHRootController ()<SHLineGraphViewDelegate>
@property (nonatomic, strong) NSArray *xValues;
@property (nonatomic, strong) NSArray *yValues;
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

    NSMutableArray *xValues = [NSMutableArray array];
    NSMutableArray *yValues = [NSMutableArray array];

    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.hour = -1;
    NSCalendar *calendar = [NSCalendar currentCalendar];

    NSDate *date = [NSDate date];
    for (int i=0; i<13; i++) {
        [xValues insertObject:date atIndex:0];
        [yValues addObject:@(i * 1024 + 5000)];
        date = [calendar dateByAddingComponents:components toDate:date options:0];
    }

    _xValues = xValues;
    _yValues = yValues;
//    _plottingValues = @[
//                              @6058,
//                              @2000,
//                              @2303,
//                              @2200,
//                              @1200,
//                              @4500,
//                              @5600,
//                              @970,
//                              @6507,
//                              @1002,
//                              @6709,
//                              @2300
//                              ];

    [_lineGraph reloadGraphWithAnimated:YES];

    [self.view addSubview:_lineGraph];
}

#pragma mark - SHLineGraphViewDelegate

-(NSString *)titleForLineGraph:(SHLineGraphView *)lineGraph
{
    return @"Line Graph Title";
}

-(NSInteger)numberOfPlotsInLineGraph:(SHLineGraphView *)lineGraph
{
    return 2;
}

-(NSInteger)lineGraph:(SHLineGraphView *)lineGraph numberOfPointsInPlotIndex:(NSInteger)plotIndex
{
    return [_xValues count];
//    return 2;
//    return [_plottingValues count];
}

-(NSString *)lineGraph:(SHLineGraphView *)lineGraph titleForPlotIndex:(NSInteger)plotIndex
{
    return @"Segment";
}

-(double)lineGraph:(SHLineGraphView *)lineGraph XValueInPlotIndex:(NSInteger)plotIndex forPoint:(NSInteger)pointIndex
{
//    if (pointIndex == 0) {
//        return [[[NSDate date] dateByAddingTimeInterval:-1 * 60 * 60 * 24] timeIntervalSince1970];
//    }
//    else {
//        return [[NSDate date] timeIntervalSince1970];
//    }
//    NSDate *date = [NSDate date];
//    NSTimeInterval interval = -1 * 60 * 60 * 24 * ([_plottingValues count]-pointIndex);
//    return [[date dateByAddingTimeInterval:interval] timeIntervalSince1970];
//    return pointIndex + plotIndex;
    return [_xValues[pointIndex] timeIntervalSince1970];
}

-(double)lineGraph:(SHLineGraphView *)lineGraph YValueInPlotIndex:(NSInteger)plotIndex forPoint:(NSInteger)pointIndex
{
    return [_yValues[pointIndex] doubleValue] - 1000 * plotIndex;
//    return [[_plottingValues objectAtIndex:pointIndex] doubleValue] + plotIndex * 200;
}

//-(BOOL)lineGraph:(SHLineGraphView *)lineGraph hiddenForPlotIndex:(NSInteger)plotIndex
//{
//    return plotIndex == 0;
//}

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
