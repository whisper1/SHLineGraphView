//
//  SHHoverView.h
//  SHLineGraphView
//
//  Created by whisper on 7/22/14.
//  Copyright (c) 2014 grevolution. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHHoverLabel : UILabel

@property (nonatomic, strong) UIColor *borderColor;
@property (nonatomic, assign) CGFloat borderWidth;
@property (nonatomic, assign) CGFloat cornerRadius;

+(SHHoverLabel *)hoverLabelAtPoint:(CGPoint)point inView:(UIView *)view withAttributedText:(NSAttributedString *)attributedText;

-(void)showAtPoint:(CGPoint)point inView:(UIView *)view withAttributedText:(NSAttributedString *)attributedText;

@end
