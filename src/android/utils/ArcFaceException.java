package com.contron.cordova.arcface.utils;

/**
 * Created by liweifa on 2017/11/28.
 */

public class ArcFaceException extends Exception {
    int errorCode;

    public ArcFaceException(int errorCode) {
        this.errorCode = errorCode;
    }

    public int getErrorCode() {
        return errorCode;
    }


    @Override
    public String getMessage() {
        String message = "";
        switch (errorCode) {
            case 0x0001:
                message = "MERR_BASIC_BASE";
                break;
            case 0x0002:
                message = "MERR_UNKNOWN";
                break;
            case 0x0003:
                message = "MERR_UNSUPPORTED";
                break;
            case 0x0004:
                message = "MERR_NO_MEMORY";
                break;
            case 0x0005:
                message = "MERR_BAD_STATE";
                break;
            case 0x0009:
                message = "MERR_BUFFER_OVERFLOW";
                break;
            case 0x000a:
                message = "MERR_BUFFER_UNDERFLOW";
                break;
            case 0x000b:
                message = "INVALID_PARAMETER";
                break;
            case 0x000c:
                message = "NO_FACE_IN";
                break;
            case 0x000d:
                message = "NO_FACE_REGISTERED";
                break;
            case 0x7000:
                message = "MERR_FSDK_BASE";
                break;
            case 0x7001:
                message = "MERR_FSDK_INVALID_APP_ID";
                break;
            case 0x7002:
                message = "MERR_FSDK_INVALID_SDK_ID";
                break;
            case 0x7003:
                message = "MERR_FSDK_INVALID_ID_PAIR";
                break;
            case 0x7004:
                message = "MERR_FSDK_MISMATCH_ID_AND_SDK";
                break;
            case 0x7005:
                message = "MERR_FSDK_SYSTEM_VERSION_UNSUPPORTED";
                break;
            case 0x7006:
                message = "MERR_FSDK_LICENCE_EXPIRED";
                break;
            case 0x12000:
                message = "MERR_FSDK_FR_ERROR_BASE";
                break;
            case 0x12001:
                message = "MERR_FSDK_FR_INVALID_MEMORY_INFO";
                break;
            case 0x12002:
                message = "MERR_FSDK_FR_INVALID_IMAGE_INFO";
                break;
            case 0x12003:
                message = "MERR_FSDK_FR_INVALID_FACE_INFO";
                break;
            case 0x12004:
                message = "MERR_FSDK_FR_NO_GPU_AVAILABLE";
                break;
            case 0x12005:
                message = "MERR_FSDK_FR_MISMATCHED_FEATURE_LEVEL";
                break;
        }
        return message;
    }
}
