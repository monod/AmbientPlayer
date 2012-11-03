//
//  APSoundCellBackView.m
//  AmbientPlayer
//
//  Created by OHKI Yoshihito on 2012/10/08.
//  Copyright (c) 2012年 Veronica Software. All rights reserved.
//

#import "APSoundCellBackView.h"

@implementation APSoundCellBackView

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        UINib *nib = [UINib nibWithNibName:@"APSoundCellBackView" bundle:[NSBundle mainBundle]];
        NSArray *array = [nib instantiateWithOwner:self options:nil];
        UIView *view = [array objectAtIndex:0];
        UIImage *backgroundImage = [UIImage imageNamed:@"paper"];
        view.backgroundColor = [UIColor colorWithPatternImage:backgroundImage];
        [self addSubview:view];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
