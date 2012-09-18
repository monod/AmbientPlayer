//
//  APGradientBackgroundView.m
//  AmbientPlayer
//
//  Created by OHKI Yoshihito on 2012/09/19.
//  Copyright (c) 2012年 InteractionPlus. All rights reserved.
//

#import "APGradientBackgroundView.h"

@implementation APGradientBackgroundView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.opaque = NO;
        self.selected = NO;
        
        CGColorSpaceRef colorSpace;
        size_t num_locations = 2;
        CGFloat locations[2] = { 0.5, 1.0 };
        CGFloat components[8] = {
            0.0, 0.0, 0.0, 0,     // Start color
            0.0, 0.0, 0.0, 0.6   // End color
        };
        colorSpace = CGColorSpaceCreateDeviceRGB();
        gradient = CGGradientCreateWithColorComponents(colorSpace, components, locations, num_locations);
        CGColorSpaceRelease(colorSpace);
    }
    return self;
}

- (void)dealloc
{
    CGGradientRelease(gradient);
}

- (void)drawRect:(CGRect)rect
{
    // Drawing code
    if (self.selected) {
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGPoint startPoint = CGPointMake(0.0, 0.0);
        CGPoint endPoint = CGPointMake(0.0, self.frame.size.height);
        CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    } else {
        [[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.4] setFill];
        UIRectFill(rect);
    }
}

@end
