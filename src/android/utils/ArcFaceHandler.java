package com.contron.cordova.arcface.utils;

import android.os.Handler;
import android.os.Message;

import com.contron.cordova.arcface.bean.FaceEntity;

import java.util.List;

/**
 * Created by liweifa on 2017/11/28.
 */

public class ArcFaceHandler extends Handler {
    private int countOfThread ;
    private int finalCountOfFace ;
    private ArcFaceListener faceListener;
    private List<FaceEntity> faceList;
    private int num ;

    public ArcFaceHandler(int countOfThread, int finalCountOfFace, ArcFaceListener faceListener, List<FaceEntity> faceList) {
        this.countOfThread = countOfThread;
        this.finalCountOfFace = finalCountOfFace;
        this.faceListener = faceListener;
        this.faceList = faceList;
        num = 0;
    }

    @Override
    public void handleMessage(Message msg) {
        super.handleMessage(msg);
        switch (msg.what) {
            case 0:
                num = countOfThread + num;
                if (num >= finalCountOfFace) {
                    if (faceListener != null) {
                        faceListener.onFaceSearchFinish(faceList);
                    }
                }
                break;
            case -1:
                if (faceListener != null) {
                    int code = msg.getData().getInt("code");
                }
                break;
        }
    }

}
