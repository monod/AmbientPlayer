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

-(id)initWithTitle:(NSString *)title fileName:(NSString *)fileName {
    self = [self init];
    if (self) {
        self.title = title;
        self.fileName = fileName;
    }
    return self;
}

- (id) initWithTitle:(NSString *)title fileName:(NSString *)fileName image:(NSString *)imageFileName description:(NSString *)description {
    self = [self initWithTitle:title fileName:fileName];
    if (self) {
        self.imageFileName = imageFileName;
        self.description = description;
    }
    return self;
}

+ (NSString *) recordedFileDirectory {
    // Get documents directory
	NSArray *arrayPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    return 	[arrayPaths objectAtIndex:0];
}

- (NSURL *)getRecordedFileURL {
    return [NSURL fileURLWithPath:[self getRecordedFilePath]];
}

- (NSString *)getRecordedFilePath {
    return [[APSoundEntry recordedFileDirectory] stringByAppendingPathComponent:self.fileName];
}

- (NSString *) getRecordedImageFilePath {
    return [[APSoundEntry recordedFileDirectory] stringByAppendingPathComponent:self.imageFileName];
}

- (NSURL *) getRecordedImageFileURL {
    return [NSURL fileURLWithPath:[self getRecordedImageFilePath]];
}

- (UIImage *)getRecordedImage {
    return [UIImage imageWithContentsOfFile:[self getRecordedImageFilePath]];
}


@end
