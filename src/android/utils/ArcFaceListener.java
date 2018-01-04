package com.contron.cordova.arcface.utils;

import com.contron.cordova.arcface.bean.FaceEntity;

import java.util.List;

/**
 * Created by liweifa on 2017/11/24.
 */

public interface ArcFaceListener {
    /**
     * 查询完成后的回调接口
     * @param faceEntityList
     */
    void onFaceSearchFinish(List<FaceEntity> faceEntityList);
}
