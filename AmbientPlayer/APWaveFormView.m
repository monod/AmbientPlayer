//
//  APWaveFormView.m
//  AmbientPlayer
//
//  Created by OHKI Yoshihito on 2012/10/07.
//  Copyright (c) 2012年 Veronica Software. All rights reserved.
//

#import "APWaveFormView.h"

@implementation APWaveFormView

const float kTouchAreaSize = 16;
const float kSelectedEdgeWidth = 4;

typedef enum edgeType {
    EdgeNone,
    EdgeLeft,
    EdgeTop,
    EdgeRight,
    EdgeBottom
} EdgeType;

CGRect _boundingBox;
EdgeType _selectedEdge;
UIBezierPath *_selectedPath;

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
    _prevX = kTouchAreaSize;
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
    
    _boundingBox = CGRectMake(kTouchAreaSize, kTouchAreaSize, 0, 0);
    _selectedEdge = EdgeNone;
}

- (void)resetSample {
    _path = [UIBezierPath bezierPath];
    _boundingBox = CGRectMake(kTouchAreaSize, kTouchAreaSize, 0, 0);
    _prevX = kTouchAreaSize;
}

- (void)addSampleAt:(NSTimeInterval)time withValue:(float)value {
    if (0 == self.duration) {
        return;
    }
    
    CGFloat x = (float)time / self.duration * (self.bounds.size.width - kTouchAreaSize * 2) + kTouchAreaSize;
    
    float linearVal = [self dBToLinearValue:value];
    CGFloat h = MAX(2.0, linearVal * self.bounds.size.height);
    CGFloat y = (self.bounds.size.height - h) / 2.0;
    [_path moveToPoint:CGPointMake(x, y)];
    [_path addLineToPoint:CGPointMake(x, y + h)];
    _prevX = x;
    _maxValue = MAX(_maxValue, linearVal);
    
    _boundingBox.size.height = MAX(kTouchAreaSize, _maxValue * (self.bounds.size.height - kTouchAreaSize * 2));
    _boundingBox.origin.y = (self.bounds.size.height - _boundingBox.size.height) / 2.0;
    [self setNeedsDisplay];
}

- (void)expandToFit {
    CGFloat sx = (self.bounds.size.width - kTouchAreaSize * 2) / (_prevX - kTouchAreaSize);
    CGAffineTransform at = CGAffineTransformMakeTranslation(-_boundingBox.origin.x, -_boundingBox.origin.y);
    [_path applyTransform:at];
    at = CGAffineTransformMakeScale(sx, 1.0);
    [_path applyTransform:at];
    at = CGAffineTransformMakeTranslation(_boundingBox.origin.x, _boundingBox.origin.y);
    [_path applyTransform:at];
    _boundingBox.size.width = self.bounds.size.width - kTouchAreaSize * 2;
    [self setNeedsDisplay];
}

- (void)showHandle:(BOOL)show {
    _showHandle = show;
    [self setNeedsDisplay];
}

# pragma mark Touch Events

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = (UITouch *)[touches anyObject];
    CGPoint p = [touch locationInView:self];
    
    if (ABS(_boundingBox.origin.x - p.x) < kTouchAreaSize) {
        // Left edge
        _selectedEdge = EdgeLeft;
        [self setNeedsDisplay];
    } else if (ABS(_boundingBox.origin.x + _boundingBox.size.width - p.x) < kTouchAreaSize) {
        // Right edge
        _selectedEdge = EdgeRight;
        [self setNeedsDisplay];
    } else if (ABS(_boundingBox.origin.y - p.y) < kTouchAreaSize) {
        // Top edge
        _selectedEdge = EdgeTop;
        [self setNeedsDisplay];
    } else if (ABS(_boundingBox.origin.y + _boundingBox.size.height - p.y) < kTouchAreaSize) {
        // Bottom edge
        _selectedEdge = EdgeBottom;
        [self setNeedsDisplay];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = (UITouch *)[touches anyObject];
    CGPoint p = [touch locationInView:self];

    if (_selectedEdge == EdgeLeft) {
        CGFloat right = _boundingBox.origin.x + _boundingBox.size.width;
        if (kTouchAreaSize < p.x && p.x < right) {
            _boundingBox.origin.x = p.x;
            _boundingBox.size.width = right - p.x;
            [self setNeedsDisplay];
        }
    } else if (_selectedEdge == EdgeRight) {
        if (_boundingBox.origin.x < p.x && p.x < self.bounds.size.width - kTouchAreaSize) {
            _boundingBox.size.width = p.x - _boundingBox.origin.x;
            [self setNeedsDisplay];
        }
    } else if (_selectedEdge == EdgeTop) {
        CGFloat bottom = _boundingBox.origin.y + _boundingBox.size.height;
        if (kTouchAreaSize < p.y && p.y < bottom) {
            _boundingBox.origin.y = p.y;
            _boundingBox.size.height = self.bounds.size.height - p.y * 2;
            [self setNeedsDisplay];
        }
    } else if (_selectedEdge == EdgeBottom) {
        if (_boundingBox.origin.y < p.y && p.y < self.bounds.size.height - kTouchAreaSize) {
            _boundingBox.origin.y = self.bounds.size.height - p.y;
            _boundingBox.size.height = self.bounds.size.height - _boundingBox.origin.y * 2;
            [self setNeedsDisplay];
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    _selectedEdge = EdgeNone;
    [self setNeedsDisplay];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    _selectedEdge = EdgeNone;
    [self setNeedsDisplay];
}

#pragma mark Draw method

const float kMarkSize = 6;

- (void)drawRect:(CGRect)rect {
    // Drawing code
    if (_showHandle) {
        
        // NOTE: Commented out for the time being
        /*
        [[UIColor grayColor] setFill];
        UIBezierPath *bg = [UIBezierPath bezierPathWithRect:_boundingBox];
        [bg fill];
        
        UIBezierPath *path = [UIBezierPath bezierPath];
        _selectedPath = nil;
        
        // Left
        CGPoint q1 = CGPointMake(_boundingBox.origin.x, self.bounds.origin.y + kMarkSize);
        CGPoint q2 = CGPointMake(q1.x - kMarkSize, q1.y - kMarkSize);
        CGPoint p1 = CGPointMake(_boundingBox.origin.x, self.bounds.origin.y);
        CGPoint p2 = CGPointMake(_boundingBox.origin.x, self.bounds.origin.y + self.bounds.size.height);
        CGPoint q3 = CGPointMake(_boundingBox.origin.x - kMarkSize, p2.y);
        CGPoint q4 = CGPointMake(_boundingBox.origin.x, q3.y - kMarkSize);
        
        [path moveToPoint:q1];
        [path addLineToPoint:q2];
        [path addLineToPoint:p1];
        [path addLineToPoint:p2];
        [path addLineToPoint:q3];
        [path addLineToPoint:q4];
        if (_selectedEdge == EdgeLeft) {
            _selectedPath = [UIBezierPath bezierPath];
            [_selectedPath moveToPoint:p1];
            [_selectedPath addLineToPoint:p2];
        }
        
        // Right
        q1 = CGPointMake(_boundingBox.origin.x + _boundingBox.size.width, self.bounds.origin.y + kMarkSize);
        q2 = CGPointMake(q1.x + kMarkSize, q1.y - kMarkSize);
        p1 = CGPointMake(_boundingBox.origin.x + _boundingBox.size.width, self.bounds.origin.y);
        p2 = CGPointMake(_boundingBox.origin.x + _boundingBox.size.width, self.bounds.origin.y + self.bounds.size.height);
        q3 = CGPointMake(p2.x + kMarkSize, p2.y);
        q4 = CGPointMake(q3.x - kMarkSize, q3.y - kMarkSize);

        [path moveToPoint:q1];
        [path addLineToPoint:q2];
        [path addLineToPoint:p1];
        [path addLineToPoint:p2];
        [path addLineToPoint:q3];
        [path addLineToPoint:q4];
        if (_selectedEdge == EdgeRight) {
            _selectedPath = [UIBezierPath bezierPath];
            [_selectedPath moveToPoint:p1];
            [_selectedPath addLineToPoint:p2];
        }
        
        // Top
        q1 = CGPointMake(self.bounds.origin.x + kMarkSize, _boundingBox.origin.y);
        q2 = CGPointMake(q1.x - kMarkSize, q1.y - kMarkSize);
        p1 = CGPointMake(self.bounds.origin.x, _boundingBox.origin.y);
        p2 = CGPointMake(self.bounds.origin.x + self.bounds.size.width, _boundingBox.origin.y);
        q3 = CGPointMake(p2.x, p2.y - kMarkSize);
        q4 = CGPointMake(q3.x - kMarkSize, q3.y + kMarkSize);

        [path moveToPoint:q1];
        [path addLineToPoint:q2];
        [path addLineToPoint:p1];
        [path addLineToPoint:p2];
        [path addLineToPoint:q3];
        [path addLineToPoint:q4];
        if (_selectedEdge == EdgeTop) {
            _selectedPath = [UIBezierPath bezierPath];
            [_selectedPath moveToPoint:p1];
            [_selectedPath addLineToPoint:p2];
        }
        
        // Bottom
        q1 = CGPointMake(self.bounds.origin.x + kMarkSize, _boundingBox.origin.y + _boundingBox.size.height);
        q2 = CGPointMake(q1.x - kMarkSize, q1.y + kMarkSize);
        p1 = CGPointMake(self.bounds.origin.x, _boundingBox.origin.y + _boundingBox.size.height);
        p2 = CGPointMake(self.bounds.origin.x + self.bounds.size.width, _boundingBox.origin.y + _boundingBox.size.height);
        q3 = CGPointMake(p2.x, p2.y + kMarkSize);
        q4 = CGPointMake(q3.x - kMarkSize, q3.y - kMarkSize);
        
        [path moveToPoint:q1];
        [path addLineToPoint:q2];
        [path addLineToPoint:p1];
        [path addLineToPoint:p2];
        [path addLineToPoint:q3];
        [path addLineToPoint:q4];
        if (_selectedEdge == EdgeBottom) {
            _selectedPath = [UIBezierPath bezierPath];
            [_selectedPath moveToPoint:p1];
            [_selectedPath addLineToPoint:p2];
        }
        
        [[UIColor yellowColor] setStroke];
        [[UIColor yellowColor] setFill];
        [path stroke];
        [path fill];
        _selectedPath.lineWidth = 4.0;
        [_selectedPath stroke];
         */
    }
    
    [[UIColor whiteColor] setStroke];
    [_path stroke];
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
