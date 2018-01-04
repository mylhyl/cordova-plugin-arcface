//
//  ArcSoftDataManager.m
//  ArcSoftEx
//
//  Created by summer on 17/12/21.
//  Copyright © 2017年 cygcontron. All rights reserved.
//

#import "ArcSoftManager.h"
#import "ammem.h"
#import "merror.h"
#import "arcsoft_fsdk_face_recognition.h"
#import "arcsoft_fsdk_face_tracking.h"
#import "arcsoft_fsdk_face_detection.h"
#import "common_utilitys.h"

#import "FaceModel.h"
#import "DatabaseManager.h"
#import "MJExtension.h"
#import "FaceEntity.h"

#import <LzmaSDK_ObjC/LzmaSDKObjC.h>

#define AFR_APP_ID         ""
#define AFR_SDK_FR_KEY     ""
#define AFR_SDK_FT_KEY     ""
#define AFR_SDK_FD_KEY     ""

#define AFR_FR_MEM_SIZE         1024*1024*40
#define AFR_FT_MEM_SIZE         1024*1024*5
#define AFR_FD_MEM_SIZE         1024*1024*5

#define AFR_FD_MAX_FACE_NUM     4

NSString * const _Nonnull kArcSoftManagerDomain = @"ArcSoftManager";
NSString * const _Nonnull kArcSoftFaceSDKDomain = @"ArcSoftFaceSDK";
NSString * const _Nonnull kArcSoftFaceSDKError =@"Calling ArcSoftSDK method error. Please check merror.h in ArcSoftSDK.";
//初始化引擎错误
NSString * const _Nonnull kArcSoftFaceSDKFTError = @"Init FT engine error.";
NSString * const _Nonnull kArcSoftFaceSDKFDError = @"Init FD engine error.";
NSString * const _Nonnull kArcSoftFaceSDKFRError = @"Init FR engine error.";
//解压缩初始化错误
NSString * const _Nonnull kArcSoftManagerFileNotFound = @"Decode File Not Found.";
NSString * const _Nonnull kArcSoftManagerExtractError = @"Decoder not created. Extract Error.";
NSString * const _Nonnull kArcSoftManagerFileFormatError = @"The file is not the specified format(.7z).";
NSString * const _Nonnull kArcSoftManagerSqlExecuteError = @"Sql not found.";
//查找人脸错误
NSString * const _Nonnull kArcSoftManagerNOFaceIn = @"Failed to detect face.";
NSString * const _Nonnull kArcSoftManagerNORegisteredFace = @"NO registered face in database.";
NSString * const _Nonnull kArcSoftManagerRegisteredFaceError = @"Registered face failure.";


static ArcSoftManager *manager=nil;


@interface ArcSoftManager ()
{
    MHandle          _arcsoftFD;
    MVoid*           _memBufferFD;
    
    MHandle          _arcsoftFT;
    MVoid*           _memBufferFT;
    
    MHandle          _arcsoftFR;
    MVoid*           _memBufferFR;
    
    ASVLOFFSCREEN*   _offscreenForProcessFR;
    dispatch_semaphore_t _processSemaphore;
    dispatch_semaphore_t _processFRSemaphore;
    
    ASVLOFFSCREEN*   _offscreenIn;
    
    DatabaseManager *DbManager;
}

@end

@implementation ArcSoftManager

//初始化Manager
+(instancetype)sharedInstance
{
    if(manager==nil)
    {
        manager=[[[self class] alloc] init];
    }
    return manager;
}

-(instancetype)init
{
    if(self=[super init])
    {
        DbManager=[DatabaseManager sharedInstance];
    }
    return self;
}

//初始化引擎
-(BOOL)initEnginesAppID:(NSString *)appId FTKey:(NSString *)ftKey FDKey:(NSString *)fdKey FRKey:(NSString *)frKey Error:(NSError *__autoreleasing*)error;
{
    // FT
    _memBufferFT = MMemAlloc(MNull,AFR_FT_MEM_SIZE);
    MMemSet(_memBufferFT, 0, AFR_FT_MEM_SIZE);
    MRESULT res = AFT_FSDK_InitialFaceEngine((MPChar)[appId UTF8String], (MPChar)[ftKey UTF8String], (MByte*)_memBufferFT, AFR_FT_MEM_SIZE, &_arcsoftFT, AFT_FSDK_OPF_0_HIGHER_EXT, 16, AFR_FD_MAX_FACE_NUM);
    if(res!=MOK)
    {
        if(error) *error=[NSError errorWithDomain:kArcSoftFaceSDKDomain code:res userInfo:@{NSLocalizedDescriptionKey : kArcSoftFaceSDKFTError}];
        return NO;
    }
    // FD
    _memBufferFD = MMemAlloc(MNull, AFR_FD_MEM_SIZE);
    MMemSet(_memBufferFD, 0, AFR_FD_MEM_SIZE);
    res=AFD_FSDK_InitialFaceEngine((MPChar)[appId UTF8String], (MPChar)[fdKey UTF8String], (MByte*)_memBufferFD, AFR_FD_MEM_SIZE, &_arcsoftFD, AFD_FSDK_OPF_0_HIGHER_EXT, 16, AFR_FD_MAX_FACE_NUM);
    if(res!=MOK)
    {
        if(error) *error=[NSError errorWithDomain:kArcSoftFaceSDKDomain code:res userInfo:@{NSLocalizedDescriptionKey : kArcSoftFaceSDKFDError}];
        return NO;
    }
    // FR
    _memBufferFR = MMemAlloc(MNull,AFR_FR_MEM_SIZE);
    MMemSet(_memBufferFR, 0, AFR_FR_MEM_SIZE);
    res=AFR_FSDK_InitialEngine((MPChar)[appId UTF8String], (MPChar)[frKey UTF8String], (MByte*)_memBufferFR, AFR_FR_MEM_SIZE, &_arcsoftFR);
    if(res!=MOK)
    {
        if(error) *error=[NSError errorWithDomain:kArcSoftFaceSDKDomain code:res userInfo:@{NSLocalizedDescriptionKey : kArcSoftFaceSDKFRError}];
        return NO;
    }
    
    _processSemaphore = dispatch_semaphore_create(1);
    _processFRSemaphore = dispatch_semaphore_create(1);
    
    return YES;
}

//销毁引擎
-(BOOL)dellocEngines
{
    if(0 == dispatch_semaphore_wait(_processSemaphore, DISPATCH_TIME_FOREVER))
    {
        if(AFT_FSDK_UninitialFaceEngine(_arcsoftFT)!=MOK) return NO;
        _arcsoftFT = MNull;
        if(_memBufferFT != MNull)
        {
            MMemFree(MNull, _memBufferFT);
            _memBufferFT = MNull;
        }
        
        if(AFD_FSDK_UninitialFaceEngine(_arcsoftFD)!=MOK) return NO;
        _arcsoftFD = MNull;
        if(_memBufferFD != MNull)
        {
            MMemFree(MNull, _memBufferFD);
            _memBufferFD = MNull;
        }
        
        dispatch_semaphore_signal(_processSemaphore);
        _processSemaphore = NULL;
    }
    
    if(0 == dispatch_semaphore_wait(_processFRSemaphore, DISPATCH_TIME_FOREVER))
    {
        if(AFR_FSDK_UninitialEngine(_arcsoftFR)!=MOK) return NO;
        _arcsoftFR = MNull;
        if(_memBufferFR != MNull)
        {
            MMemFree(MNull,_memBufferFR);
            _memBufferFR = MNull;
        }
        
        _offscreenForProcessFR = MNull;
        
        dispatch_semaphore_signal(_processFRSemaphore);
        _processFRSemaphore = NULL;
    }
    return YES;
}

#pragma mark - 
-(BOOL)executeDataByZipFilePath:(NSString *)path outputDirectory:(NSString *)directory Error:(NSError *__autoreleasing*)error;
{
    BOOL isErrorExist=NO;
    NSError *extractError=nil;
    if(![self extractDataByPath:path outputDirectory:directory Error:&extractError])
    {
        if(error) *error=[NSError errorWithDomain:kArcSoftManagerDomain code:-1 userInfo:extractError.userInfo];
        isErrorExist=YES;
    }
    
    NSFileManager * fileManager = [NSFileManager defaultManager];
    NSString *sqlDirPath=[NSString stringWithFormat:@"%@arcface/sql",directory];
    NSArray *sqlArr=[fileManager contentsOfDirectoryAtPath:sqlDirPath error:nil];
    if(sqlArr.count==0)
    {
        if(error) *error=[NSError errorWithDomain:kArcSoftManagerDomain code:-1 userInfo:@{NSLocalizedDescriptionKey : kArcSoftManagerSqlExecuteError}];
        isErrorExist=YES;
    }
    for(NSString *sqlPath in sqlArr)
    {
        NSString *sql = [NSString stringWithContentsOfFile:[NSString stringWithFormat:@"%@/%@",sqlDirPath,sqlPath] encoding:NSUTF8StringEncoding error:nil];
        [DbManager registerBySql:sql];
    }
    return !isErrorExist;
}

-(NSString *)searchFace:(NSString *)image Count:(int)count Error:(NSError *__autoreleasing*)error;
{
    NSError *createFaceError=nil;
    FaceModel *model=[self createFaceModelUserId:0 GroupId:0 PicName:@"" Remark:@"" Image:image Error:&createFaceError];
    if(error) *error=[NSError errorWithDomain:createFaceError.domain code:createFaceError.code userInfo:createFaceError.userInfo];
    
    NSArray *arr=[DbManager getAllFaceModel];
    if(arr.count==0)
    {
        if(error) *error=[NSError errorWithDomain:kArcSoftManagerDomain code:-1 userInfo:@{NSLocalizedDescriptionKey : kArcSoftManagerNORegisteredFace}];
    }
    
    AFR_FSDK_FACEMODEL refModel = {0};
    NSData *refFeatureData=[[NSData alloc] initWithBase64EncodedString:model.code options:NSDataBase64DecodingIgnoreUnknownCharacters];
    refModel.pbFeature=(MByte *)[refFeatureData bytes];
    refModel.lFeatureSize=22020;
    
//    //最大相似率
//    float smi=0.0;
//    //最相似Model
//    FaceModel *frModel;
    
    NSMutableArray *faceArr=[NSMutableArray array];
    for(FaceModel *fModel in arr)
    {
        AFR_FSDK_FACEMODEL probeModel = {0};
        probeModel.lFeatureSize=22020;
        
        NSData *probeFeatureData=[[NSData alloc] initWithBase64EncodedString:fModel.code options:NSDataBase64DecodingIgnoreUnknownCharacters];
        probeModel.pbFeature=(MByte *)[probeFeatureData bytes];
        
        float smi_re;
        MRESULT res=AFR_FSDK_FacePairMatching(_arcsoftFR, &refModel, &probeModel, &smi_re);
        FaceEntity *entity=[[FaceEntity alloc] init];
        entity.source=smi_re;
        entity.model=fModel;
        if(res==0)
        {
            [faceArr addObject:entity];
            if(faceArr.count>count)
            {
                [faceArr sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                    return [obj1 compare:obj2];
                }];
                [faceArr removeLastObject];
            }
        }
        else
        {
            if(error) *error=[NSError errorWithDomain:kArcSoftFaceSDKDomain code:res userInfo:@{NSLocalizedDescriptionKey : kArcSoftFaceSDKError}];
        }
    }
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[FaceEntity mj_keyValuesArrayWithObjectArray:faceArr] options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    return jsonString;
}

-(BOOL)registerFaceUserId:(int)userId GroupId:(int)grorpId ImagePath:(NSString *)path Remark:(NSString *)remark Error:(NSError *__autoreleasing*)error;
{
    BOOL isErrorExist=NO;
    UIImage *image=[UIImage imageWithContentsOfFile:path];
    NSData *data=UIImageJPEGRepresentation(image,0);
    
    NSString *base64Str=[data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    NSError *createFaceError=nil;
    FaceModel *model=[self createFaceModelUserId:userId GroupId:grorpId PicName:[path stringByDeletingPathExtension] Remark:remark Image:base64Str Error:&createFaceError];
    if(error && createFaceError)
    {
        *error=[NSError errorWithDomain:createFaceError.domain code:createFaceError.code userInfo:createFaceError.userInfo];
        isErrorExist=YES;
    }
    if(error && ![DbManager registerFaceModel:model])
    {
        
        isErrorExist=YES;
    }
        
    return !isErrorExist;
}

#pragma mark -
//创建人脸Model
-(FaceModel *)createFaceModelUserId:(int)userId GroupId:(int)groupId PicName:(NSString *)picName Remark:(NSString *)remark Image:(NSString *)image Error:(NSError *__autoreleasing*)error;
{
    ASVLOFFSCREEN offscreen=[self offscreenFromBase64Str:image];
    
    LPAFD_FSDK_FACERES pFaceRes = MNull;
    MRESULT res = AFD_FSDK_StillImageFaceDetection(_arcsoftFD, &offscreen, &pFaceRes);
    if(res!=0) *error=[NSError errorWithDomain:kArcSoftFaceSDKDomain code:res userInfo:@{NSLocalizedDescriptionKey : kArcSoftFaceSDKError}];
    if(pFaceRes->nFace==0) *error=[NSError errorWithDomain:kArcSoftManagerDomain code:-1 userInfo:@{NSLocalizedDescriptionKey : kArcSoftManagerNOFaceIn}];
    
    int index = 0;
    if(pFaceRes->nFace>1)
    {
        int w[AFR_FD_MAX_FACE_NUM] = {0};
        for(int i = 0; i < pFaceRes->nFace; i++)
        {
            w[i] = pFaceRes->rcFace[i].right - pFaceRes->rcFace[i].left;
            if(i>0 && w[i]>w[i-1])
                index = i;
        }
    }
    
    AFR_FSDK_FACEINPUT FRInput = {0};
    AFR_FSDK_FACEMODEL FRModel = {0};
    FRInput.lOrient = pFaceRes->lfaceOrient[index];
    FRInput.rcFace.left = pFaceRes->rcFace[index].left;
    FRInput.rcFace.top = pFaceRes->rcFace[index].top;
    FRInput.rcFace.right = pFaceRes->rcFace[index].right;
    FRInput.rcFace.bottom = pFaceRes->rcFace[index].bottom;
    res =AFR_FSDK_ExtractFRFeature(_arcsoftFR, &offscreen, &FRInput, &FRModel);
    
    NSData *featureData;
    NSString *code=@"";
    if(res==0 && FRModel.lFeatureSize>0 && FRModel.pbFeature!=NULL)
    {
        featureData = [[NSData alloc] initWithBytes:FRModel.pbFeature length:FRModel.lFeatureSize];//MByte*转NSData*
        code=[featureData base64EncodedStringWithOptions:0];
    }
    else if(res!=0) *error=[NSError errorWithDomain:kArcSoftFaceSDKDomain code:res userInfo:@{NSLocalizedDescriptionKey : kArcSoftFaceSDKError}];
    
    FaceModel *model=[[FaceModel alloc] init];
    model.userId=userId;
    model.groupId=groupId;
    model.picName=picName;
    model.code=code;
    model.remark=remark;
    
    return model;
}

- (ASVLOFFSCREEN)offscreenFromBase64Str:(NSString *)base64Str
{
    NSData *decodedImageData = [[NSData alloc] initWithBase64EncodedString:base64Str options:NSDataBase64DecodingIgnoreUnknownCharacters];
    UIImage *image = [UIImage imageWithData:decodedImageData];
    
    ASVLOFFSCREEN g_imgInfo = {0};
    g_imgInfo.i32Width = (MInt32)image.size.width;
    g_imgInfo.i32Height = (MInt32)image.size.height;
    unsigned char* pBGRA = [common_utilitys bitmapFromImage:image:0];
    
    
    g_imgInfo.u32PixelArrayFormat = ASVL_PAF_RGB24_B8G8R8;//ASVL_PAF_NV21;//ASVL_PAF_RGB24_B8G8R8;
    if(g_imgInfo.u32PixelArrayFormat == ASVL_PAF_RGB24_B8G8R8)
    {
        g_imgInfo.pi32Pitch[0] = LINE_BYTES(g_imgInfo.i32Width,24);
        g_imgInfo.ppu8Plane[0] = (MUInt8*)malloc(g_imgInfo.i32Height*LINE_BYTES(g_imgInfo.i32Width,24));
        RGBA8888ToBGR(pBGRA, g_imgInfo.i32Width,g_imgInfo.i32Height,g_imgInfo.i32Width*4, g_imgInfo.ppu8Plane[0]);//原格式是RGBA
    }
    
    return g_imgInfo;
}

//解压文件
-(BOOL)extractDataByPath:(NSString *)path outputDirectory:(NSString *)directory Error:(NSError *__autoreleasing*)error;
{
    //判断文件是否存在
    NSFileManager *fManager=[NSFileManager defaultManager];
    if(![fManager fileExistsAtPath:path])
    {
        if(error) *error=[NSError errorWithDomain:kArcSoftManagerDomain code:-1 userInfo:@{ NSLocalizedDescriptionKey : kArcSoftManagerFileNotFound}];
        return NO;
    }
    if(![[path pathExtension] isEqualToString:@"7z"])
    {
        if(error) *error=[NSError errorWithDomain:kArcSoftManagerDomain code:-1 userInfo:@{ NSLocalizedDescriptionKey : kArcSoftManagerFileFormatError}];
        return NO;
    }
    
    LzmaSDKObjCReader *reader = [[LzmaSDKObjCReader alloc] initWithFileURL:[NSURL fileURLWithPath:path]
                                                                   andType:LzmaSDKObjCFileType7z];
    NSError * extractError = nil;
    if (![reader open:&extractError]) {
        if(error) *error=[NSError errorWithDomain:kArcSoftManagerDomain code:-1 userInfo:extractError.userInfo];
        return NO;
    }
    
    NSMutableArray * items = [NSMutableArray array];
    [reader iterateWithHandler:^BOOL(LzmaSDKObjCItem * item, NSError * error){
        if (item)
        {
            [items addObject:item];
        }
        return YES;
    }];
    
    if(![reader extract:items toPath:directory withFullPaths:YES])
    {
        if(error) *error=[NSError errorWithDomain:kArcSoftManagerDomain code:-1 userInfo:@{NSLocalizedDescriptionKey : kArcSoftManagerExtractError}];
        return NO;
    }
    return YES;
}

@end
