//
//  APSoundEntry.h
//  AmbientPlayer
//
//  Created by KAWACHI Takashi on 9/8/12.
//  Copyright (c) 2012 InteractionPlus. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface APSoundEntry : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *description;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *imageFileName;
@property (nonatomic, copy) NSManagedObjectID *moID; //CoreDataのデータを操作するために対応するデータのキー情報だけは持たせておく
@property (nonatomic, copy) NSString *soundCloudURL;
@property (nonatomic) BOOL isSoundCloudFile;

-(id)initWithTitle:(NSString *)title fileName:(NSString *)fileName;
-(id)initWithTitle:(NSString *)title fileName:(NSString *)fileName image:(NSString *)imageFileName description:(NSString *)description;
+(NSString *) recordedFileDirectory;

-(NSURL *) getRecordedFileURL;
-(NSURL *) getRecordedImageFileURL;
-(NSString *) getRecordedFilePath;
-(NSString *) getRecordedImageFilePath;
-(UIImage *) getRecordedImage;
-(void) finishUploadingSoundCloud:(NSString *)soundCloudURL;

@end
