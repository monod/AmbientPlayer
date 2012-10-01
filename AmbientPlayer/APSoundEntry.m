//
//  APSoundEntry.m
//  AmbientPlayer
//
//  Created by KAWACHI Takashi on 9/8/12.
//  Copyright (c) 2012 InteractionPlus. All rights reserved.
//

#import "APSoundEntry.h"

#define SYNTHESIZE(propertyName) @synthesize propertyName = _ ## propertyName

@implementation APSoundEntry
SYNTHESIZE(title);
SYNTHESIZE(fileName);

-(id)initWithTitle:(NSString *)title withFileName:(NSString *)fileName {
    self = [self init];
    if (self) {
        self.title = title;
        self.fileName = fileName;
    }
    return self;
}

- (id) initWithTitle:(NSString *)title withFileName:(NSString *)fileName andImageFileName:(NSString *)imageFileName {
    self = [self initWithTitle:title withFileName:fileName];
    if (self) {
        self.imageFileName = imageFileName;
    }
    return self;
}

+ (NSString *) recordedFileDirectory {
    // Get documents directory
	NSArray *arrayPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    return 	[arrayPaths objectAtIndex:0];
}

@end
