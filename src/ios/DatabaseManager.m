//
//  DatabaseManager.m
//  ArcSoftEx
//
//  Created by summer on 17/12/22.
//  Copyright © 2017年 cygcontron. All rights reserved.
//

#import "DatabaseManager.h"
#import "FMDB.h"

@interface DatabaseManager ()
{
    FMDatabase *_database;
}
@end

@implementation DatabaseManager+(id)sharedInstance
{
    static DatabaseManager *dc = nil;
    if(dc == nil)
    {
        dc = [[[self class] alloc] init];
    }
    return dc;
}

-(id)init
{
    if(self = [super init])
    {
        [self configDatabase];
    }
    return self;
}

-(void)configDatabase
{
    //创建数据库
    NSString *path = [NSString stringWithFormat:@"%@/Documents/arcface.sqlite",NSHomeDirectory()];
    _database = [[FMDatabase alloc] initWithPath:path];
    if(!_database.open)
    {
        NSLog(@"创建失败");
        return;
    }
    
    //创建数据表
    NSString *sql = @"create table if not exists face  ("
    " userId int not null, "
    " groupId int not null, "
    " picName varchar, "
    " code varchar,"
    " remark varchar, "
    " createTime varchar,"
    " updateTime varchar"
    ");";
    BOOL b = [_database executeUpdate:sql];
    if(!b)
    {
        NSLog(@"创建表失败");
    }
//    NSString *sql2=@"alter table face add PRIMARY KEY(userId，groupId)";
//    b=[_database executeUpdate:sql2];
//    if(!b)
//    {
//        NSLog(@"添加主键失败");
//    }
}

-(BOOL)registerFaceModel:(FaceModel *)model
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *dateTime = [formatter stringFromDate:[NSDate date]];

    FMResultSet *resultSet=[_database executeQueryWithFormat:@"select * from face where userId = %d and groupId = %d",model.userId,model.groupId];
    if([resultSet next])
    {
        BOOL b = [_database executeUpdateWithFormat:@"update face set picName=%@,code=%@,remark=%@,updateTime=%@ where userId=%d and groupId=%d",model.picName,model.code,model.remark,dateTime,model.userId,model.groupId];
        if(!b)
        {
            NSLog(@"更新失败");
        }
        return b;
    }
    else
    {
        BOOL b = [_database executeUpdateWithFormat:@"insert into face(userId,groupId,picName,code,remark,createTime) values(%d,%d,%@,%@,%@,%@);",model.userId,model.groupId,model.picName,model.code,model.remark,dateTime];
        if(!b)
        {
            NSLog(@"插入失败");
        }
        return b;
    }
}

-(BOOL)registerBySql:(NSString *)sql
{
    [_database beginTransaction];
    NSArray *array = [sql componentsSeparatedByString:@";"];
    NSMutableArray *array2=[NSMutableArray arrayWithArray:array];
    [array2 removeLastObject];
    
    BOOL isRollBack = NO;
    @try {
        for(NSString *str in array2)
        {
            BOOL b=[_database executeUpdate:str];
            if(!b)
            {
                NSLog(@"failedSql=%@",str);
                NSLog(@"执行sql失败");
            }
        }
    }
    @catch (NSException *exception) {
        isRollBack = YES;
        [_database rollback];
    }
    @finally {
        if (!isRollBack) {
            [_database commit];
        }
    }
    return YES;
}

-(NSArray *)getAllFaceModel
{
    //FMResultSet *s=[_database executeQuery:@"SELECT COUNT(*) FROM Face"];
    
    FMResultSet *resultSet = [_database executeQueryWithFormat:@"SELECT * FROM face"];
    NSMutableArray *marr = [[NSMutableArray alloc] init];
    while ([resultSet next]) {
        FaceModel *model=[[FaceModel alloc] init];
        model.userId=[resultSet intForColumn:@"userId"];
        model.groupId=[resultSet intForColumn:@"groupId"];
        model.picName=[resultSet stringForColumn:@"picName"];
        model.code=[resultSet stringForColumn:@"code"];
        model.remark=[resultSet stringForColumn:@"remark"];
        [marr addObject:model];
    }
    return marr;
}
@end
