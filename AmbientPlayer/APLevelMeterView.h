//
//  APLevelMeterView.h
//  AmbientPlayer
//
//  Created by OHKI Yoshihito on 2012/10/03.
//  Copyright (c) 2012年 Veronica Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifndef LEVELMETER_CLAMP
#define LEVELMETER_CLAMP(min,x,max) (x < min ? min : (x > max ? max : x))
#endif

@interface APLevelMeterView : UIView {
    float _ch0;
    float _ch1;
	float _decibelResolution;
	float _scaleFactor;
    float _minDecibels;
    int _tableSize;
    float _root;
    NSMutableArray* _table;    
}

- (void)updateValuesWith:(float) ch0 ch:(float) ch1;

@property BOOL vertical;
@property int nLights;
@property (nonatomic, strong) UIColor *fgColor;
@property (nonatomic, strong) UIColor *bgColor;
@end
