package com.contron.cordova.arcface.utils;

import android.content.Context;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Handler;
import android.util.Base64;

import com.arcsoft.facedetection.AFD_FSDKEngine;
import com.arcsoft.facedetection.AFD_FSDKError;
import com.arcsoft.facedetection.AFD_FSDKFace;
import com.arcsoft.facerecognition.AFR_FSDKEngine;
import com.arcsoft.facerecognition.AFR_FSDKError;
import com.arcsoft.facerecognition.AFR_FSDKFace;
import com.arcsoft.facerecognition.AFR_FSDKMatching;

import com.contron.cordova.arcface.ArcFacePlugin;
import com.contron.cordova.arcface.bean.FaceEntity;
import com.contron.cordova.arcface.db.dao.FaceDao;

import java.util.ArrayList;
import java.util.List;


public final class ArcFaceUtils {
    /**
     * 一张图片中人脸坐标集合
     *
     * @param data   图片 nv21格式
     * @param width  图片宽
     * @param height 图片高
     * @return
     */
    private static List<AFD_FSDKFace> getFaceInfo(byte[] data, int width, int height) throws ArcFaceException {
        AFD_FSDKEngine engine = new AFD_FSDKEngine();
        // 用来存放检测到的人脸信息列表
        List<AFD_FSDKFace> result = new ArrayList<AFD_FSDKFace>();
        //初始化人脸检测引擎，使用时请替换申请的APPID和SDKKEY
        AFD_FSDKError err = engine.AFD_FSDK_InitialFaceEngine(ArcFacePlugin.APP_ID, ArcFacePlugin.SDK_FD_KEY, AFD_FSDKEngine.AFD_OPF_0_HIGHER_EXT, 16, 5);
        if (err.getCode() != AFR_FSDKError.MOK) {
            throw new ArcFaceException(err.getCode());
        }
        //输入的data数据为NV21格式（如Camera里NV21格式的preview数据），其中height不能为奇数，人脸检测返回结果保存在result。
        err = engine.AFD_FSDK_StillImageFaceDetection(data, width, height, AFD_FSDKEngine.CP_PAF_NV21, result);
        if (err.getCode() != AFR_FSDKError.MOK) {
            throw new ArcFaceException(err.getCode());
        }
        //销毁人脸检测引擎
        err = engine.AFD_FSDK_UninitialFaceEngine();
        if (err.getCode() != AFR_FSDKError.MOK) {
            throw new ArcFaceException(err.getCode());
        }
        return result;
    }

    /**
     * 提取特征码
     *
     * @param image 图片Base64
     * @return
     */
    public static AFR_FSDKFace getFaceCode(String image) throws ArcFaceException {

        byte[] imageSource = Base64.decode(image, Base64.NO_WRAP);
        Bitmap bitmap = BitmapFactory.decodeByteArray(imageSource, 0, imageSource.length);
        int width;
        int height;
        width = bitmap.getWidth();
        height = bitmap.getHeight();
        //宽高不能为奇数
        if (width % 2 != 0) {
            width = width - 1;
        }
        if (height % 2 != 0) {
            height = height - 1;
        }
        byte[] data = ImageUtil.getNV21(width, height, bitmap);
        bitmap.recycle();
        imageSource = null;
        bitmap = null;
        List<AFD_FSDKFace> list = getFaceInfo(data, width, height);
        if (list.size() > 0) {
            AFR_FSDKFace face = new AFR_FSDKFace();
            AFR_FSDKEngine engine = new AFR_FSDKEngine();
            AFD_FSDKFace afd_fsdkFace = list.get(0);
            //初始化人脸识别引擎，使用时请替换申请的APPID 和SDKKEY
            AFR_FSDKError error = engine.AFR_FSDK_InitialEngine(ArcFacePlugin.APP_ID, ArcFacePlugin.SDK_FR_KEY);
            if (error.getCode() != AFR_FSDKError.MOK) {
                throw new ArcFaceException(error.getCode());
            }
            //输入的data数据为NV21格式（如Camera里NV21格式的preview数据）；人脸坐标一般使用人脸检测返回的Rect传入；人脸角度请按照人脸检测引擎返回的值传入。
            error = engine.AFR_FSDK_ExtractFRFeature(data, width, height, AFR_FSDKEngine.CP_PAF_NV21, afd_fsdkFace.getRect(), afd_fsdkFace.getDegree(), face);
            if (error.getCode() != AFR_FSDKError.MOK) {
                throw new ArcFaceException(error.getCode());
            }
            engine.AFR_FSDK_UninitialEngine();
            data = null;
            return face;
        } else {
            data = null;
            throw new ArcFaceException(ArcFaceErrorCode.NO_FACE_IN);
        }

    }

    /**
     * 人脸特征码对比
     *
     * @param ref   注册的人脸
     * @param input 要识别的人脸
     * @return
     */
    public static AFR_FSDKMatching facePairMatching(AFR_FSDKFace ref, AFR_FSDKFace input) throws ArcFaceException {
        if (ref == null || input == null) {
            throw new ArcFaceException(ArcFaceErrorCode.INVALID_PARAMETER);
        }
        AFR_FSDKEngine engine = new AFR_FSDKEngine();
        //初始化人脸识别引擎，使用时请替换申请的APPID 和SDKKEY
        AFR_FSDKError error = engine.AFR_FSDK_InitialEngine(ArcFacePlugin.APP_ID, ArcFacePlugin.SDK_FR_KEY);
        if (error.getCode() != AFR_FSDKError.MOK) {
            throw new ArcFaceException(error.getCode());
        }
        //score用于存放人脸对比的相似度值
        AFR_FSDKMatching score = new AFR_FSDKMatching();
        error = engine.AFR_FSDK_FacePairMatching(ref, input, score);
        if (error.getCode() != AFR_FSDKError.MOK) {
            throw new ArcFaceException(error.getCode());
        }
        //销毁人脸识别引擎
        engine.AFR_FSDK_UninitialEngine();
        return score;
    }


    private final static int countOfThread = 20;//一个线程固定获取20个值

    /**
     * 获取对比后的人脸列表
     *
     * @param context
     * @param image   进行对比的图片
     * @param count   返回的数量
     * @return
     */
    public static void getFaceEntities(Context context, String image, final int count, final ArcFaceListener faceListener) throws ArcFaceException {
        //先获取数据库中的集合数量，以便后面计算使用
        FaceDao faceDao = FaceDao.newInitialize(context.getApplicationContext());
        int countOfFace = 0;
        Cursor cursor = faceDao.getDatabase().query(FaceEntity.TABLE_NAME, new String[]{"count(*)"}, null, null, null, null, null);
        if (cursor.moveToFirst()) {
            countOfFace = cursor.getInt(0);
        }
        cursor.close();
        if (countOfFace == 0) {
            throw new ArcFaceException(ArcFaceErrorCode.NO_FACE_REGISTERED);
        }
        final List<FaceEntity> faceList = new ArrayList<FaceEntity>();
        Handler handler = new ArcFaceHandler(countOfThread, countOfFace, faceListener, faceList);
        AFR_FSDKFace refFace = ArcFaceUtils.getFaceCode(image);
        if (refFace == null) {
            throw new ArcFaceException(ArcFaceErrorCode.NO_FACE_IN);
        }
        byte[] refB = refFace.getFeatureData();
        for (int i = 0; i < countOfFace; i = i + countOfThread) {
            Runnable runnable = new ArcFaceThread(context, faceList, count, i + "," + countOfThread, handler, refB);
            ThreadUtil.execute(runnable);
        }
    }
}
