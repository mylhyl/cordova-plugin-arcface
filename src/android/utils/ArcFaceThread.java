package com.contron.cordova.arcface.utils;

import android.content.Context;
import android.database.Cursor;
import android.os.Handler;
import android.os.Message;
import android.util.Base64;

import com.arcsoft.facerecognition.AFR_FSDKEngine;
import com.arcsoft.facerecognition.AFR_FSDKError;
import com.arcsoft.facerecognition.AFR_FSDKFace;
import com.arcsoft.facerecognition.AFR_FSDKMatching;

import com.contron.cordova.arcface.ArcFacePlugin;
import com.contron.cordova.arcface.bean.FaceEntity;
import com.contron.cordova.arcface.db.dao.FaceDao;


import java.util.List;

/**
 * 人脸识别主方法
 * Created by liweifa on 2017/11/24.
 */

class ArcFaceThread implements Runnable {
    private Context context;
    private int count;
    private String limit;
    private Handler handler;

    private byte[] refB;

    private List<FaceEntity> faceList;

    private static final Object object = new Object();

    private static final String[] projection = {
            FaceEntity.COLUMN_NAME_USER_ID,
            FaceEntity.COLUMN_NAME_GROUP_ID,
            FaceEntity.COLUMN_NAME_PIC_NAME,
            FaceEntity.COLUMN_NAME_CODE,
            FaceEntity.COLUMN_NAME_REMARK,
            FaceEntity.COLUMN_NAME_CREATE_TIME,
            FaceEntity.COLUMN_NAME_UPDATE_TIME
    };

    /**
     *
     * @param context
     * @param faceList 返回的人脸特征码集合
     * @param count 所需返回的人脸数
     * @param limit sql语句中的过滤条件
     * @param handler 回到函数
     * @param refB 所要匹配的人脸特征码
     */
    ArcFaceThread(Context context, List<FaceEntity> faceList, int count, String limit, Handler handler, byte[] refB) {
        this.count = count;
        this.faceList = faceList;
        this.context = context;
        this.limit = limit;
        this.handler = handler;
        this.refB = refB;

    }

    @Override
    public void run() {
        FaceDao faceDao = FaceDao.newInitialize(context.getApplicationContext());
        final Cursor cursor = faceDao.getDatabase().query(FaceEntity.TABLE_NAME, projection, null, null, null, null, null, limit);
        AFR_FSDKEngine engine = new AFR_FSDKEngine();
        //初始化人脸识别引擎，使用时请替换申请的APPID 和SDKKEY
        AFR_FSDKError error = engine.AFR_FSDK_InitialEngine(ArcFacePlugin.APP_ID, ArcFacePlugin.SDK_FR_KEY);
        //score用于存放人脸对比的相似度值
        AFR_FSDKMatching score = new AFR_FSDKMatching();
        if (cursor.moveToFirst()) {
            do {
                String code = cursor.getString(cursor.getColumnIndex(FaceEntity.COLUMN_NAME_CODE));
                byte[] inputB = Base64.decode(code, Base64.DEFAULT);
                error = engine.AFR_FSDK_FacePairMatching(new AFR_FSDKFace(refB), new AFR_FSDKFace(inputB), score);
                synchronized (object) {
                    if (faceList.size() == 0) {
                        FaceEntity face = new FaceEntity();
                        face.setUserId(cursor.getInt(cursor.getColumnIndex(FaceEntity.COLUMN_NAME_USER_ID)));
                        face.setGroupId(cursor.getInt(cursor.getColumnIndex(FaceEntity.COLUMN_NAME_GROUP_ID)));
                        face.setPicName(cursor.getString(cursor.getColumnIndex(FaceEntity.COLUMN_NAME_PIC_NAME)));
                        face.setCode(code);
                        face.setRemark(cursor.getString(cursor.getColumnIndex(FaceEntity.COLUMN_NAME_REMARK)));
                        face.setCreateTime(cursor.getLong(cursor.getColumnIndex(FaceEntity.COLUMN_NAME_CREATE_TIME)));
                        face.setUpdateTime(cursor.getLong(cursor.getColumnIndex(FaceEntity.COLUMN_NAME_UPDATE_TIME)));
                        face.setSource(score.getScore());
                        faceList.add(face);
                    } else {
                        for (int i = 0; i < faceList.size(); i++) {
                            if (score.getScore() > faceList.get(i).getSource()) {
                                FaceEntity face = new FaceEntity();
                                face.setUserId(cursor.getInt(cursor.getColumnIndex(FaceEntity.COLUMN_NAME_USER_ID)));
                                face.setPicName(cursor.getString(cursor.getColumnIndex(FaceEntity.COLUMN_NAME_PIC_NAME)));
                                face.setCode(code);
                                face.setRemark(cursor.getString(cursor.getColumnIndex(FaceEntity.COLUMN_NAME_REMARK)));
                                face.setSource(score.getScore());
                                face.setCreateTime(cursor.getLong(cursor.getColumnIndex(FaceEntity.COLUMN_NAME_CREATE_TIME)));
                                face.setUpdateTime(cursor.getLong(cursor.getColumnIndex(FaceEntity.COLUMN_NAME_UPDATE_TIME)));
                                faceList.add(i, face);
                                if (faceList.size() > count) {
                                    faceList.remove(faceList.size() - 1);
                                    break;
                                }
                            }

                        }
                    }
                }

            } while (cursor.moveToNext());
        }
        cursor.close();
        //销毁人脸识别引擎
        error = engine.AFR_FSDK_UninitialEngine();
        Message message = handler.obtainMessage(0);
        handler.sendMessage(message);

    }
}
