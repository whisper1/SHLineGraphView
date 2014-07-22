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

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    //initate the graph view
    SHLineGraphView *_lineGraph = [[SHLineGraphView alloc] initWithFrame:CGRectMake(0, 0, 568, 320)];
    _lineGraph.delegate = self;
    _lineGraph.bezierMode = YES;

    //set the main graph area theme attributes

    /**
     *  theme attributes dictionary. you can specify graph theme releated attributes in this dictionary. if this property is
     *  nil, then a default theme setting is applied to the graph.
     */
    NSDictionary *_themeAttributes = @{
                                       kXAxisLabelColorKey : [UIColor colorWithRed:0.48 green:0.48 blue:0.49 alpha:1.0],
                                       kXAxisLabelFontKey : [UIFont fontWithName:@"HelveticaNeue" size:10],
                                       kYAxisLabelColorKey : [UIColor colorWithRed:0.48 green:0.48 blue:0.49 alpha:1.0],
                                       kYAxisLabelFontKey : [UIFont fontWithName:@"HelveticaNeue" size:10],
                                       kYAxisLabelSideMarginsKey : @20,
                                       kPlotBackgroundLineColorKey : [UIColor colorWithRed:0.48 green:0.48 blue:0.49 alpha:0.4],
                                       kDotSizeKey : @5
                                       };
    _lineGraph.themeAttributes = _themeAttributes;

    _lineGraph.xAxisUnit = kSHLineGraphUnit_Integer;
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

    [_lineGraph reloadGraph];

    [self.view addSubview:_lineGraph];
}

#pragma mark - SHLineGraphViewDelegate

-(NSInteger)numberOfPlotsInLineGraph:(SHLineGraphView *)lineGraph
{
    return 2;
}

-(NSInteger)lineGraph:(SHLineGraphView *)lineGraph numberOfPointsInPlotIndex:(NSInteger)plotIndex
{
    return [_plottingValues count];
}

-(SHDataPoint *)lineGraph:(SHLineGraphView *)lineGraph dataPointInPlotIndex:(NSInteger)plotIndex ForPoint:(NSInteger)pointIndex
{
    SHDataPoint *dataPoint = [[SHDataPoint alloc] init];
    dataPoint.x = (double)pointIndex + plotIndex;
    dataPoint.y = [[_plottingValues objectAtIndex:pointIndex] doubleValue] + plotIndex * 200;
    return dataPoint;
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
