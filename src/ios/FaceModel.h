//
//  FaceModel.h
//  ArcSoftEx
//
//  Created by summer on 17/12/22.
//  Copyright © 2017年 cygcontron. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FaceModel : NSObject

@property (assign,nonatomic) int userId;
@property (assign,nonatomic) int groupId;
@property (strong,nonatomic) NSString *picName;
@property (strong,nonatomic) NSString *code;
@property (strong,nonatomic) NSString *remark;
@property (strong,nonatomic) NSString *createTime;
@property (strong,nonatomic) NSString *updateTime;

@end
