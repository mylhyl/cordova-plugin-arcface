# 介绍
cordova 离线人脸识别插件，使用[虹软SDK](http://www.arcsoft.com.cn)，暂时只支持arm类型的CPU，因为官方还没64位SDK。

# 插件安装

```bash
cordova plugin add cordova-plugin-arcface --variable ANDROID_APP_ID="<ANDROID_APP_ID>" --variable ANDROID_SDK_FD_KEY="<ANDROID_SDK_FD_KEY>" --variable ANDROID_SDK_FR_KEY="<ANDROID_SDK_FR_KEY>" --variable Android_SDK_FT_KEY="<Android_SDK_FT_KEY>" --variable IOS_APP_ID="<IOS_APP_ID>" --variable IOS_SDK_FD_KEY="<IOS_SDK_FD_KEY>" --variable IOS_SDK_FR_KEY="<IOS_SDK_FR_KEY>" --variable IOS_SDK_FT_KEY="<IOS_SDK_FT_KEY>" --save
```

由于此插件包大，建议选择本地安装
```base
cordova plugin add D:\cordovaPlugin\github\cordova-plugin-arcface --variable ANDROID_APP_ID="<ANDROID_APP_ID>" --variable ANDROID_SDK_FD_KEY="<ANDROID_SDK_FD_KEY>" --variable ANDROID_SDK_FR_KEY="<ANDROID_SDK_FR_KEY>" --variable Android_SDK_FT_KEY="<Android_SDK_FT_KEY>" --variable IOS_APP_ID="<IOS_APP_ID>" --variable IOS_SDK_FD_KEY="<IOS_SDK_FD_KEY>" --variable IOS_SDK_FR_KEY="<IOS_SDK_FR_KEY>" --variable IOS_SDK_FT_KEY="<IOS_SDK_FT_KEY>" --save
```

# 插件列表
```base
cordova plugin list
```

# 插件删除
```bash
cordova plugin remove cordova-plugin-arcface
```

# 插件使用

导入人脸数据
```javascript
ArcFace.executeData(
        srcFilePath,//压缩文件，只支持7z格式
        destDir,//解压目录路径
        res => {
            //解压成功
        },
        err => {
            //失败
            err.code
            err.message
        });
```

单个注册人脸
```javascript
ArcFace.registerFace(
        userId,//用户ID
        groupId,//分组ID
        photoPath,//图像文件路径
        remark,//备注
        res => {
            //成功
        },err => {
            //失败
            err.code
            err.message
        });
```

人脸验证
```javascript
ArcFace.searchFace(
        imageData,//base64图像
        backCount,//返回人脸相似度数量
        res => {
            //成功返回json数组，数组大于根据 backCount
            res.data
        },
        err => {
            //失败
            err.code
            err.message
        });
```

# 二次封装

[传送门](https://github.com/mylhyl/cordova-plugin-arcface/blob/master/doc/ArcFaceServ.ts)