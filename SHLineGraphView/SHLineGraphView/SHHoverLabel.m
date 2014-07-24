//
//  SHHoverView.m
//  SHLineGraphView
//
//  Created by whisper on 7/22/14.
//  Copyright (c) 2014 grevolution. All rights reserved.
//

#import "SHHoverLabel.h"

#define MARGIN 30.0
#define TEXT_PADDING 5.0
#define ANIMATION_DURATION 0.15

@implementation SHHoverLabel

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setUpDefaults];
    }
    return self;
}

//-(id)init
//{
//    if (self = [super init]) {
//        [self setUpDefaults];
//    }
//    return self;
//}

-(void)setUpDefaults
{
    self.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.8];
    self.borderColor = [UIColor blueColor];
    self.borderWidth = 1.0;
    self.cornerRadius = 3.0;
    self.layer.masksToBounds = YES;
}

#pragma mark - UILabel

-(void)drawTextInRect:(CGRect)rect
{
    UIEdgeInsets insets = UIEdgeInsetsMake(TEXT_PADDING, TEXT_PADDING, TEXT_PADDING, TEXT_PADDING);
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, insets)];
}

#pragma mark - Properties

-(void)setBorderWidth:(CGFloat)borderWidth
{
    _borderWidth = borderWidth;
    self.layer.borderWidth = borderWidth;
}

-(void)setBorderColor:(UIColor *)borderColor
{
    _borderColor = borderColor;
    self.layer.borderColor = borderColor.CGColor;
}

-(void)setCornerRadius:(CGFloat)cornerRadius
{
    _cornerRadius = cornerRadius;
    self.layer.cornerRadius = cornerRadius;
}

#pragma mark - Class Methods

+(SHHoverLabel *)hoverLabelAtPoint:(CGPoint)point inView:(UIView *)view withAttributedText:(NSAttributedString *)attributedText
{
    CGSize textSize = [attributedText size];
    CGSize size = CGSizeMake(textSize.width + TEXT_PADDING*2,
                             textSize.height + TEXT_PADDING*2);
    CGRect frame = [SHHoverLabel frameForPoint:point inView:view withSize:size];
    SHHoverLabel *hoverLabel = [[SHHoverLabel alloc] initWithFrame:frame];
    [hoverLabel showAtPoint:point inView:view withAttributedText:attributedText];
    return hoverLabel;
}

#pragma mark - Public

-(void)showAtPoint:(CGPoint)point inView:(UIView *)view withAttributedText:(NSAttributedString *)attributedText
{
    CGSize textSize = [attributedText size];
    CGSize size = CGSizeMake(textSize.width + TEXT_PADDING*2,
                             textSize.height + TEXT_PADDING*2);
    CGRect frame = [SHHoverLabel frameForPoint:point inView:view withSize:size];

    self.attributedText = attributedText;
    self.lineBreakMode = NSLineBreakByWordWrapping;
    self.numberOfLines = 0;

    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        self.frame = frame;
    }];
    self.layer.zPosition = 10;
}

+(CGRect)frameForPoint:(CGPoint)point inView:(UIView *)view withSize:(CGSize)size
{
    //default origin: left, yCenter
    CGPoint origin = CGPointMake(point.x - size.width - MARGIN,
                                 point.y - size.height/2);

    if (origin.x < view.bounds.origin.x) {
        origin.x = point.x + MARGIN;
    }
    if (origin.x + size.width > view.bounds.origin.x + view.bounds.size.width) {
        origin.x = point.x - size.width - MARGIN;
    }

    if (origin.y < view.bounds.origin.y) {
        origin.y = point.y + MARGIN;
    }
    if (origin.y + size.height > view.bounds.origin.y + view.bounds.size.height) {
        origin.y = point.y - size.height - MARGIN;
    }

    return CGRectMake(origin.x, origin.y, size.width, size.height);
}

@end
