//
//  APCustomSoundEntryModel.m
//  AmbientPlayer
//
//  Created by 瀬戸山 雅人 on 2012/10/27.
//  Copyright (c) 2012年 Veronica Software. All rights reserved.
//

#import "APCustomSoundEntryModel.h"
#import "APSoundEntry.h"


@implementation APCustomSoundEntryModel

@dynamic sound_file;
@dynamic image_file;
@dynamic latitude;
@dynamic longitude;
@dynamic name;
@dynamic desc;
@dynamic user_name;
@dynamic attribution;
@dynamic option1;
@dynamic option2;
@dynamic is_sound_cloud_file;
@dynamic sound_cloud_url;


- (BOOL)soundRecorded {
    if (self.sound_file != nil) {
        return YES;
    } else {
        return NO;
    }
}

+ (NSMutableArray *)getAllSoundEntriesIn:(NSManagedObjectContext *)managedObjectContext {
    //保存した.m4aファイルからAPSoundEntryを生成する処理
    NSMutableArray *recordedSoundEntries = [NSMutableArray array];

    //NSLog(@"manegedObjectContext is %@", managedObjectContext);

    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"APCustomSoundEntryModel" inManagedObjectContext:managedObjectContext];
    [request setEntity:entity];

    NSError *error = nil;
    NSArray *mutableFetchResults = [managedObjectContext
            executeFetchRequest:request error:&error];
    if (mutableFetchResults == nil || error) {
        // エラーを処理する
        NSLog(@"%@", error);
        //空の配列を返しておく。
        return recordedSoundEntries;
    }

    //APCustomSoundEntryModelからビュー表示用のAPSoundEntryに変換する

    for (APCustomSoundEntryModel *soundModelInDB in mutableFetchResults) {
        APSoundEntry *newEntry = [[APSoundEntry alloc] initWithTitle:soundModelInDB.name fileName:soundModelInDB.sound_file];
        newEntry.moID = soundModelInDB.objectID;
        if (soundModelInDB.image_file) {
            newEntry.imageFileName = soundModelInDB.image_file;
        }

        if (soundModelInDB.desc) {
            newEntry.description = soundModelInDB.desc;
        }

        if (soundModelInDB.is_sound_cloud_file) {
            newEntry.isSoundCloudFile = soundModelInDB.is_sound_cloud_file;
        }

        if (soundModelInDB.sound_cloud_url) {
            newEntry.soundCloudURL = soundModelInDB.sound_cloud_url;
        }

        [recordedSoundEntries addObject:newEntry];
    }

    return recordedSoundEntries;
}

+ (BOOL)removeAPCustomSoundEntryModel:(NSManagedObjectID *)objectID inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {

    NSError *error = nil;
    APCustomSoundEntryModel *toDelete = (APCustomSoundEntryModel *) [managedObjectContext existingObjectWithID:objectID error:&error];
    if (error) {
        NSLog(@"%@", error);
        return NO;
    }

    if (toDelete) {
        [managedObjectContext deleteObject:toDelete];

        NSError *error = nil;
        [managedObjectContext save:&error];
        if (error) {
            NSLog(@"%@", error);
            return NO;
        }
    }
    return YES;
}

+ (BOOL)finishUploadingSoundCloud:(NSManagedObjectID *)objectID soundCloudURL:(NSString *)soundCloudURL inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSError *error = nil;
    APCustomSoundEntryModel *toUpdate = (APCustomSoundEntryModel *) [managedObjectContext existingObjectWithID:objectID error:&error];
    if (error) {
        NSLog(@"%@", error);
        return NO;
    }

    if (toUpdate) {
        toUpdate.sound_cloud_url = soundCloudURL;
        toUpdate.is_sound_cloud_file = YES;
        NSError *error = nil;


        if ([managedObjectContext hasChanges]) {
            [managedObjectContext save:&error];
        }

        if (error) {
            NSLog(@"%@", error);
            return NO;
        }
    }


    return YES;
}

@end
