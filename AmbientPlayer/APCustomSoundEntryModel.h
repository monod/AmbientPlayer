//
//  APCustomSoundEntryModel.h
//  AmbientPlayer
//
//  Created by 瀬戸山 雅人 on 2012/10/27.
//  Copyright (c) 2012年 Veronica Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface APCustomSoundEntryModel : NSManagedObject

@property (nonatomic, retain) NSString * sound_file;
@property (nonatomic, retain) NSString * image_file;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * desc;
@property (nonatomic, retain) NSString * user_name;
@property (nonatomic, retain) NSString * attribution;
@property (nonatomic, retain) NSString * option1;
@property (nonatomic, retain) NSString * option2;
@property (nonatomic) BOOL is_sound_cloud_file;


- (BOOL) soundRecorded;

+ (NSMutableArray*) getAllSoundEntriesIn:(NSManagedObjectContext *) managedObjectContext;
+ (BOOL) removeAPCustomSoundEntryModel:(NSManagedObjectID *)objectID inManagedObjectContext:(NSManagedObjectContext *) managedObjectContext;
@end
