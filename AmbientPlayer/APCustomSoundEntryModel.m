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


- (BOOL) soundRecorded
{
    if (self.sound_file != nil) {
        return YES;
    } else {
        return NO;
    }
}

+ (NSMutableArray *) getAllSoundEntriesIn:(NSManagedObjectContext *)managedObjectContext
{
    //保存した.m4aファイルからAPSoundEntryを生成する処理
    NSMutableArray *recordedSoundEntries = [NSMutableArray array];
    
    NSLog(@"manegedObjectContext is %@", managedObjectContext);
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"APCustomSoundEntryModel"                                inManagedObjectContext:managedObjectContext];
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
    
    for (APCustomSoundEntryModel *soundModelInDB in mutableFetchResults){
        APSoundEntry *newEntry = [[APSoundEntry alloc] initWithTitle:soundModelInDB.name withFileName:soundModelInDB.sound_file];
        newEntry.moID = soundModelInDB.objectID;
        [recordedSoundEntries addObject:newEntry];
    }
    
    return recordedSoundEntries;
}

+ (BOOL) removeAPCustomSoundEntryModel:(NSManagedObjectID *)objectID inManagedObjectContext:(NSManagedObjectContext *) managedObjectContext {
    
    NSError *error = nil;
    APCustomSoundEntryModel *toDelete = (APCustomSoundEntryModel *)[managedObjectContext existingObjectWithID:objectID error:&error];
    if(error) {
        NSLog(@"%@", error);
        return NO;
    }
    
    if (toDelete) {
        [managedObjectContext deleteObject:toDelete];
        
        NSError *error = nil;
        [managedObjectContext save:&error];
        if(error) {
            NSLog(@"%@", error);
            return NO;
        }
    }
    return YES;
}

@end
