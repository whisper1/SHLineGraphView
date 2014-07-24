//
//  SHPlotStyle.h
//  SHLineGraphView
//
//  Created by whisper on 7/23/14.
//  Copyright (c) 2014 grevolution. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, SHLineGraphDotStyle) {
    kSHLineGraphDotStyle_Circle,
    kSHLineGraphDotStyle_Diamond,
    kSHLineGraphDotStyle_Square,
    SHLineGraphDotStyleCount
};

typedef NS_ENUM(NSInteger, SHLineGraphLineStyle) {
    kSHLineGraphLineStyle_Solid,
    kSHLineGraphLineStyle_Dashed,
    SHLineGraphLineStyleCount
};

@interface SHPlotStyle : NSObject

@property (nonatomic, strong) UIColor *fillColor;
@property (nonatomic, strong) UIColor *strokeColor;
@property (nonatomic, assign) SHLineGraphDotStyle dotStyle;
@property (nonatomic, assign) SHLineGraphLineStyle lineStyle;
@property (nonatomic, assign) CGFloat dotSize;
@property (nonatomic, assign) CGFloat lineSize;

-(void)loadMissingDefaults;
+(SHPlotStyle *)defaultStyleForIndex:(NSUInteger)index area:(BOOL)area;

@end
