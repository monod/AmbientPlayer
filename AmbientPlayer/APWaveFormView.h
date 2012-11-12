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
    float _prevX;
    float _maxValue;
    BOOL _showHandle;
}

- (void)resetSample;
- (void)addSampleAt:(NSTimeInterval)time withValue:(float)value;
- (void)expandToFit;
- (void)showHandle:(BOOL)show;

@property (nonatomic) int duration;

@end
