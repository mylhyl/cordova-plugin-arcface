//
//  DatabaseManager.h
//  ArcSoftEx
//
//  Created by summer on 17/12/22.
//  Copyright © 2017年 cygcontron. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FaceModel.h"

@interface DatabaseManager : NSObject

+(instancetype)sharedInstance;

-(BOOL)registerFaceModel:(FaceModel *)model;

-(BOOL)registerBySql:(NSString *)sql;

-(NSArray *)getAllFaceModel;

@end
