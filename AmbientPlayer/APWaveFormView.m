//
//  APWaveFormView.m
//  AmbientPlayer
//
//  Created by OHKI Yoshihito on 2012/10/07.
//  Copyright (c) 2012年 Veronica Software. All rights reserved.
//

#import "APWaveFormView.h"

@implementation APWaveFormView

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
    _path = [UIBezierPath bezierPath];
    self.duration = 0;
    _prevX = 0;
    _maxValue = 0;
    
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
}

- (void)resetSample {
    [_path removeAllPoints];
    _prevX = 0;
}

- (void)addSampleAt:(NSTimeInterval)time withValue:(float)value {
    if (0 == self.duration) {
        return;
    }
    
    CGFloat x = (float)time / self.duration * self.frame.size.width;
    if (_prevX < (int)x) {
        float linearVal = [self dBToLinearValue:value];
        CGFloat h = MAX(2.0, linearVal * self.frame.size.height);
        CGFloat y = (self.frame.size.height - h) / 2.0;
        [_path moveToPoint:CGPointMake(x, y)];
        [_path addLineToPoint:CGPointMake(x, y + h)];
        _prevX = (int)x;
        _maxValue = MAX(_maxValue, linearVal);
        [self setNeedsDisplay];
    }
}

- (void)showBoundingBox:(BOOL)show {
    _showBoundingBox = show;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    // Drawing code
    UIColor *color = [UIColor whiteColor];
    [color setStroke];
    [_path stroke];
    
    if (_showBoundingBox) {
        color = [UIColor yellowColor];
        [color setStroke];
        CGFloat h = MAX(2.0, _maxValue * self.frame.size.height);
        CGFloat y = (self.frame.size.height - h) / 2.0;
        UIBezierPath *bb = [UIBezierPath bezierPathWithRect:CGRectMake(0, y, _prevX, h)];
        [bb stroke];
    }
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
