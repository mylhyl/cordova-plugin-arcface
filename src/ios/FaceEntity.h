//
//  FaceEntity.h
//  ARCTest2
//
//  Created by summer on 2017/12/26.
//  Copyright © 2017年 cygcontron. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FaceModel.h"

@interface FaceEntity : NSObject

@property (assign,nonatomic) float source;
@property (strong,nonatomic) FaceModel *model;

-(NSComparisonResult)compare:(FaceEntity *)other;

@end
