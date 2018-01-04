//
//  FaceEntity.m
//  ARCTest2
//
//  Created by summer on 2017/12/26.
//  Copyright © 2017年 cygcontron. All rights reserved.
//

#import "FaceEntity.h"

@implementation FaceEntity

-(NSComparisonResult)compare:(FaceEntity *)other
{
    if(self.source>other.source) return NSOrderedAscending;
    if(self.source==other.source) return NSOrderedSame;
    if(self.source<other.source) return NSOrderedDescending;
    return 0;
}
@end
