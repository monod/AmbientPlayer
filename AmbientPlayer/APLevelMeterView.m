//
//  APLevelMeterView.m
//  AmbientPlayer
//
//  Created by OHKI Yoshihito on 2012/10/03.
//  Copyright (c) 2012年 Veronica Software. All rights reserved.
//

#import "APLevelMeterView.h"

@implementation APLevelMeterView

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    _minDecibels = -80.0;
    _tableSize = 400;
    _root = 2.0;
    _decibelResolution = _minDecibels / (_tableSize - 1);
    _scaleFactor = 1.0 / _decibelResolution;
    
    _table = [NSMutableArray arrayWithCapacity:_tableSize];
    
    float minAmp = [self dbToAmp:_minDecibels];
    float ampRange = 1.0 - minAmp;
    float invAmpRange = 1.0 / ampRange;
    
    float rroot = 1.0 / _root;
    for (int i = 0; i < _tableSize; ++i) {
        float decibels = i * _decibelResolution;
        float amp = [self dbToAmp:decibels];
        float adjAmp = (amp - minAmp) * invAmpRange;
        [_table addObject: [NSNumber numberWithFloat:powf(adjAmp, rroot)]];
    }
    
    _nLights = 30;
    _fgColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.0 alpha:1.0];
    _bgColor = [UIColor blackColor];
}

- (void)drawRect:(CGRect)rect
{
    // Drawing code
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGFloat lightMinVal = 0.0;
    CGFloat insetAmount, lightVSpace;
    lightVSpace = self.bounds.size.width / (CGFloat)_nLights;
    if (lightVSpace < 4.0) {
        insetAmount = 0.0;
    } else if (lightVSpace < 8.0) {
        insetAmount = 0.5;
    } else {
        insetAmount = 1.0;
    }
    
    float level = _ch0;
    for (int i = 0; i < _nLights; i++) {
        CGFloat lightMaxVal = (CGFloat)(i + 1) / (CGFloat)_nLights;
        float lightIntensity = (level - lightMinVal) / (lightMaxVal - lightMinVal);
        lightIntensity = LEVELMETER_CLAMP(0.0, lightIntensity, 1.0);

        CGRect lightRect = CGRectMake(
            self.bounds.size.width * ((CGFloat)(i) / (CGFloat)_nLights),
            0.0,
            self.bounds.size.width * (1.0 / (CGFloat)_nLights),
            self.bounds.size.height
        );
        lightRect = CGRectInset(lightRect, insetAmount, insetAmount);
        
        [_bgColor set];
        CGContextFillRect(ctx, lightRect);
        
        if (lightIntensity == 1.0) {
            [_fgColor set];
            CGContextFillRect(ctx, lightRect);
        } else if (0.0 < lightIntensity) {
            CGColorRef clr = CGColorCreateCopyWithAlpha([_fgColor CGColor], lightIntensity);
            CGContextSetFillColorWithColor(ctx, clr);
            CGContextFillRect(ctx, lightRect);
            CGColorRelease(clr);
        }
        
        lightMinVal = lightMaxVal;
    }
}

- (void)updateValuesWith:(float)ch0 ch:(float)ch1 {
    _ch0 = [self dBToLinearValue:ch0];
    _ch1 = [self dBToLinearValue:ch1];
    [self setNeedsDisplay];
}

- (float)dBToLinearValue:(float)db {
		if (db < _minDecibels) return  0.;
		if (db >= 0.) return 1.;
		int index = (int)(db * _scaleFactor);
        NSNumber *value = [_table objectAtIndex:index];
		return [value floatValue];
}

- (float)dbToAmp:(float) db {
	return powf(10., 0.05 * db);
}

@end
