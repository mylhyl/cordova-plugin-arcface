//
//  ArcSoftDataManager.h
//  ArcSoftEx
//
//  Created by summer on 17/12/21.
//  Copyright © 2017年 cygcontron. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ArcSoftManager : NSObject

+(instancetype)sharedInstance;

//初始化引擎
-(BOOL)initEngines;
-(BOOL)initEnginesAppID:(NSString *)appId FTKey:(NSString *)ftKey FDKey:(NSString *)fdKey FRKey:(NSString *)frKey Error:(NSError *__autoreleasing*)error;
//销毁引擎
-(BOOL)dellocEngines;

//解压文件
-(BOOL)executeDataByZipFilePath:(NSString *)path outputDirectory:(NSString *)directory Error:(NSError *__autoreleasing*)error;
//查找相似人脸
-(NSString *)searchFace:(NSString *)image Count:(int)count Error:(NSError *__autoreleasing*)error;
//注册
-(BOOL)registerFaceUserId:(int)userId GroupId:(int)grorpId ImageData:(NSString *)imageData Remark:(NSString *)remark Error:(NSError *__autoreleasing*)error;
@end
