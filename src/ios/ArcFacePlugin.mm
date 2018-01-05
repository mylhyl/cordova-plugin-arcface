/********* Arc Face.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>
#import "ArcSoftManager.h"
#import "CDVFile.h"

@interface ArcFacePlugin : CDVPlugin {

  NSString* _APP_ID;
  NSString* _FD_KEY;
  NSString* _FR_KEY;
  NSString* _FT_KEY;
  
}

//定义全局实例
@property (strong,nonatomic)  ArcSoftManager *manager;

- (void)executeData:(CDVInvokedUrlCommand*)command;
- (void)searchFace:(CDVInvokedUrlCommand*)command;
- (void)registerFace:(CDVInvokedUrlCommand*)command;
- (void)getFaceCode:(CDVInvokedUrlCommand*)command;
- (void)facePairMatching:(CDVInvokedUrlCommand*)command;

@end

@implementation ArcFacePlugin

- (void)pluginInitialize
{
    NSDictionary *plistDic = [[NSBundle mainBundle] infoDictionary];
    _APP_ID = [[plistDic objectForKey:@"ArcFacePlugin"] objectForKey:@"APP_ID"];
    _FD_KEY = [[plistDic objectForKey:@"ArcFacePlugin"] objectForKey:@"FD_KEY"];
    _FR_KEY = [[plistDic objectForKey:@"ArcFacePlugin"] objectForKey:@"FR_KEY"];
    _FT_KEY = [[plistDic objectForKey:@"ArcFacePlugin"] objectForKey:@"FT_KEY"];
     //初始化插件
    self.manager=[ArcSoftManager sharedInstance];

}

- (NSString *)pathForURL:(NSString *)urlString
{
    // Attempt to use the File plugin to resolve the destination argument to a
    // file path.
    NSString *path = nil;
    id filePlugin = [self.commandDelegate getCommandInstance:@"File"];
    if (filePlugin != nil) {
        CDVFilesystemURL* url = [CDVFilesystemURL fileSystemURLWithString:urlString];
        path = [filePlugin filesystemPathForURL:url];
    }
    // If that didn't work for any reason, assume file: URL.
    if (path == nil) {
        if ([urlString hasPrefix:@"file:"]) {
            path = [[NSURL URLWithString:urlString] path];
        }
    }
    return path;
}

- (void)executeData:(CDVInvokedUrlCommand*)command
{
    [self.commandDelegate runInBackground:^{
        CDVPluginResult* pluginResult = nil;

        NSString *srcPathURL = [command.arguments objectAtIndex:0];
        NSString *destDirectoryURL = [command.arguments objectAtIndex:1];

        NSString *srcPath = [self pathForURL:srcPathURL];
        NSString *destDirectory = [self pathForURL:destDirectoryURL];

        NSError *error = nil;
        //初始化引擎
        BOOL res = [self.manager initEnginesAppID:_APP_ID FTKey:_FT_KEY FDKey:_FD_KEY FRKey:_FR_KEY Error:&error];
        if (res) {
            res = [self.manager executeDataByZipFilePath:srcPath outputDirectory:destDirectory Error:&error];
            if (res) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"ok"];
            }
        } 
        if (!res) {
            NSLog(@"%@",error);
            NSMutableDictionary* dataError = [[NSMutableDictionary alloc] init];
            [dataError setValue:[NSNumber numberWithInteger:error.code] forKey:@"code"];
            [dataError setValue:error.userInfo[NSLocalizedDescriptionKey] forKey:@"message"];
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:dataError];
        }

        //销毁引擎
        [self.manager dellocEngines];

        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)searchFace:(CDVInvokedUrlCommand*)command
{
    [self.commandDelegate runInBackground:^{
        CDVPluginResult* pluginResult = nil;
        NSString *image = [command.arguments objectAtIndex:0];
        int count = [[command.arguments objectAtIndex:1] intValue];

        NSError *error = nil;
        //初始化引擎
        BOOL res = [self.manager initEnginesAppID:_APP_ID FTKey:_FT_KEY FDKey:_FD_KEY FRKey:_FR_KEY Error:&error];
        if (res) {            
          NSString *jsonStr = [self.manager searchFace:image Count:count Error:&error];
            if (!error) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:jsonStr];                
            }
        }        
        if (!res || error) {
            NSLog(@"%@",error);
            NSMutableDictionary* dataError = [[NSMutableDictionary alloc] init];
            [dataError setValue:[NSNumber numberWithInteger:error.code] forKey:@"code"];
            [dataError setValue:error.userInfo[NSLocalizedDescriptionKey] forKey:@"message"];
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:dataError];
        }
        //销毁引擎
        [self.manager dellocEngines];

    }];
}

- (void)registerFace:(CDVInvokedUrlCommand*)command
{
    [self.commandDelegate runInBackground:^{
        CDVPluginResult* pluginResult = nil;
        int userId = [[command.arguments objectAtIndex:0] intValue];
        int groupId = [[command.arguments objectAtIndex:1] intValue];
        NSString *imageData = [command.arguments objectAtIndex:2];
        NSString *remark = [command.arguments objectAtIndex:3];
        
        NSError *error = nil;
        //初始化引擎
        BOOL res = [self.manager initEnginesAppID:_APP_ID FTKey:_FT_KEY FDKey:_FD_KEY FRKey:_FR_KEY Error:&error];    
        if (res) {
            res = [self.manager registerFaceUserId:userId GroupId:groupId imageData:imageData Remark:remark Error:&error];
            if (res) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"ok"];
            } 
        }
        
        if (!res) {            
            NSLog(@"%@",error);
            NSMutableDictionary* dataError = [[NSMutableDictionary alloc] init];
            [dataError setValue:[NSNumber numberWithInteger:error.code] forKey:@"code"];
            [dataError setValue:error.userInfo[NSLocalizedDescriptionKey] forKey:@"message"];
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:dataError];
        } 

        //销毁引擎
        [self.manager dellocEngines];
        
    }];
}

- (void)getFaceCode:(CDVInvokedUrlCommand*)command
{
    [self.commandDelegate runInBackground:^{

    }];
}

- (void)facePairMatching:(CDVInvokedUrlCommand*)command
{
    [self.commandDelegate runInBackground:^{
        
    }];
}

@end
