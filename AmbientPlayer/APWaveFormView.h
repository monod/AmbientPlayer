//
//  APWaveFormView.h
//  AmbientPlayer
//
//  Created by OHKI Yoshihito on 2012/10/07.
//  Copyright (c) 2012年 Veronica Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface APWaveFormView : UIView {
    float _decibelResolution;
	float _scaleFactor;
    float _minDecibels;
    int _tableSize;
    float _root;
    NSMutableArray *_table;
    UIBezierPath *_path;
    int _prevX;
    float _maxValue;
    BOOL _showBoundingBox;
}

- (void)resetSample;
- (void)addSampleAt:(NSTimeInterval)time withValue:(float)value;
- (void)showBoundingBox:(BOOL)show;

@property (nonatomic) int duration;

@end
