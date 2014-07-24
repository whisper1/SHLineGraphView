//
//  SHPlotStyle.m
//  SHLineGraphView
//
//  Created by whisper on 7/23/14.
//  Copyright (c) 2014 grevolution. All rights reserved.
//

#import "SHPlotStyle.h"
#import "UIColor+GraphKit.h"

@implementation SHPlotStyle

+(SHPlotStyle *)defaultStyleForIndex:(NSUInteger)index area:(BOOL)area
{
    static NSArray *defaultColors;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        defaultColors = @[
                          [UIColor gk_turquoiseColor],
                          [UIColor gk_amethystColor],
                          [UIColor gk_pumpkinColor],
                          [UIColor gk_concreteColor],
                          [UIColor gk_emerlandColor],
                          [UIColor gk_silverColor],
                          [UIColor gk_nephritisColor],
                          [UIColor gk_peterRiverColor],
                          [UIColor gk_belizeHoleColor],
                          [UIColor gk_midnightBlueColor],
                          [UIColor gk_wisteriaColor],
                          [UIColor gk_wetAsphaltColor],
                          [UIColor gk_carrotColor],
                          [UIColor gk_greenSeaColor],
                          [UIColor gk_sunflowerColor],
                          [UIColor gk_orangeColor],
                          [UIColor gk_alizarinColor],
                          [UIColor gk_pomegranateColor],
                          [UIColor gk_cloudsColor],
                          [UIColor gk_asbestosColor]];
    });
    UIColor *strokeColor = defaultColors[index % [defaultColors count]];
    UIColor *fillColor = [strokeColor colorWithAlphaComponent:(area)? 5.0 : 0.0];
    SHLineGraphDotStyle dotStyle = index % SHLineGraphDotStyleCount;
    SHLineGraphLineStyle lineStyle = (index / [defaultColors count]) % SHLineGraphLineStyleCount;

    SHPlotStyle *plotStyle = [[SHPlotStyle alloc] init];
    plotStyle.fillColor = fillColor;
    plotStyle.strokeColor = strokeColor;
    plotStyle.dotStyle = dotStyle;
    plotStyle.lineStyle = lineStyle;

    return plotStyle;
}

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
        _dotSize = 3.0;
    if (!_lineSize)
        _lineSize = 2.0;
}

@end
