package com.contron.cordova.arcface;

import android.Manifest;
import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.util.Base64;

import com.arcsoft.facerecognition.AFR_FSDKFace;
import com.arcsoft.facerecognition.AFR_FSDKMatching;
import com.contron.cordova.arcface.bean.FaceEntity;
import com.contron.cordova.arcface.db.IFaceDao;
import com.contron.cordova.arcface.db.dao.FaceDao;
import com.contron.cordova.arcface.utils.ArcFaceErrorCode;
import com.contron.cordova.arcface.utils.ArcFaceException;
import com.contron.cordova.arcface.utils.ArcFaceListener;
import com.contron.cordova.arcface.utils.ArcFaceUtils;
import com.contron.cordova.arcface.utils.ErrorMessage;
import com.contron.cordova.arcface.utils.FileUtil;
import com.contron.cordova.arcface.zip.IZip;
import com.contron.cordova.arcface.utils.PendingRequests;
import com.contron.cordova.arcface.zip.ZipFactory;

import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;

import org.apache.cordova.CordovaResourceApi;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.LOG;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.io.FileInputStream;

import java.io.IOException;
import java.io.InputStream;
import java.util.Date;
import java.util.List;


/**
 * This class echoes a string called from JavaScript.
 */
public class ArcFacePlugin extends CordovaPlugin {
    public static String APP_ID = "";
    public static String SDK_FD_KEY = "";
    public static String SDK_FR_KEY = "";
    public static String SDK_FT_KEY = "";

    private Context context;

    private static final String LOG_TAG = "ArcFacePlugin";

    public static int SECURITY_ERR = 2;

    public static final int WRITE = 3;
    public static final int READ = 4;


    private PendingRequests pendingRequests;


    private String[] permissions = {
            Manifest.permission.READ_EXTERNAL_STORAGE,
            Manifest.permission.WRITE_EXTERNAL_STORAGE};


    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);
        context = cordova.getActivity();
        try {
            ApplicationInfo applicationInfo = context.getPackageManager().getApplicationInfo(context.getPackageName(), PackageManager.GET_META_DATA);
            APP_ID = applicationInfo.metaData.getString("com.arcface.APP_ID");
            SDK_FD_KEY = applicationInfo.metaData.getString("com.arcface.facedetection.SDK_KEY");
            SDK_FR_KEY = applicationInfo.metaData.getString("com.arcface.facerecognition.SDK_KEY");
            SDK_FT_KEY = applicationInfo.metaData.getString("com.arcface.facetracking.SDK_KEY");
        } catch (PackageManager.NameNotFoundException e) {
            e.printStackTrace();
        }
        this.pendingRequests = new PendingRequests();


    }

    @Override
    public boolean execute(String action, final JSONArray args, final CallbackContext callbackContext) throws JSONException {
        //TODO 进度回调问题 是否要解决
        if (!hasReadPermission() || !hasWritePermission()) {
            int requestCode = this.pendingRequests.createRequest(args, action, callbackContext);
            this.cordova.requestPermissions(this, requestCode, permissions);
            return true;
        } else {
            return arcFaceExecute(action, args, callbackContext);
        }

    }

    private boolean arcFaceExecute(String action, final JSONArray args, final CallbackContext callbackContext) throws JSONException {
        if (action.equals("executeData")) {
            final String zipFile = args.getString(0);
            final String outputDirectory = args.getString(1);
            final String sqlDirectory = outputDirectory + "/arcface/sql";
            final boolean clearOld = false;
            cordova.getThreadPool().execute(new Runnable() {
                @Override
                public void run() {
                    IZip zip = ZipFactory.newInstance().createZip(zipFile, outputDirectory);
                    if (zip != null) {
                        boolean unZipSuccess = zip.unzipSync(zipFile, outputDirectory, clearOld, callbackContext);
                        if (unZipSuccess) {
                            upDateDataBase(sqlDirectory, callbackContext);
                        }
                    } else {
                        callbackContext.error(ErrorMessage.createErrorMessage(3, "ZIP_FORMAT_ERROR"));

                    }

                }
            });
            return true;
        } else if (action.equals("unZipFile")) {
            final String zipFile = args.getString(0);
            final String outputDirectory = args.getString(1);
            final boolean clearOld = args.getBoolean(2);
            cordova.getThreadPool().execute(new Runnable() {
                @Override
                public void run() {
                    IZip zip = ZipFactory.newInstance().createZip(zipFile, outputDirectory);
                    zip.unzipSync(zipFile, outputDirectory, clearOld, callbackContext);
                    callbackContext.success();

                }
            });
            return true;
        } else if (action.equals("executeSqlFile")) {
            final String sqlDirectory = args.getString(0);
            cordova.getThreadPool().execute(new Runnable() {
                @Override
                public void run() {
                    upDateDataBase(sqlDirectory, callbackContext);
                }
            });
            return true;
        } else if (action.equals("getFaceCode")) {
            final String image = args.getString(0);
            cordova.getThreadPool().execute(new Runnable() {
                @Override
                public void run() {
                    getFaceCode(image, callbackContext);
                }
            });
            return true;
        } else if (action.equals("facePairMatching")) {
            final String ref = args.getString(0);
            final String input = args.getString(1);
            cordova.getThreadPool().execute(new Runnable() {
                @Override
                public void run() {
                    facePairMatching(ref, input, callbackContext);

                }
            });
            return true;
        } else if (action.equals("searchFace")) {
            final String ref = args.getString(0);
            final int count = args.getInt(1);
            searchFace(ref, count, callbackContext);
            return true;
        } else if (action.equals("searchFaceForPath")) {
            final String path = args.getString(0);
            final int count = args.getInt(1);
            File file = new File(path);
            if (file.exists()) {
                try {
                    InputStream in = new FileInputStream(file);
                    byte[] b = new byte[(int) file.length()];
                    in.read(b, 0, (int) file.length());
                    String ref = Base64.encodeToString(b, Base64.NO_WRAP);
                    in.close();
                    searchFace(ref, count, callbackContext);
                } catch (IOException e) {
                    e.printStackTrace();
                }

            }

            return true;
        } else if (action.equals("registerFace")) {
            final int userId = args.getInt(0);
            final int groupId = args.getInt(1);
            final String imagePath = args.getString(2);
            final String remark = args.getString(3);
            cordova.getThreadPool().execute(new Runnable() {
                @Override
                public void run() {
                    updateOrRegisterFace(userId, groupId, imagePath, remark, callbackContext);

                }
            });
            return true;
        } else if (action.equals("deleteFace")) {
            int userId = args.getInt(0);
            this.deleteFace(userId, callbackContext);
            return true;
        }
        callbackContext.error("invalid action");
        return false;

    }

    /**
     * 获取人脸特征码
     *
     * @param image           图片Base64
     * @param callbackContext
     */
    private void getFaceCode(String image, CallbackContext callbackContext) {
        if (image != null && image.length() > 0) {
            AFR_FSDKFace face;
            try {
                face = ArcFaceUtils.getFaceCode(image);
                JSONObject jsonObject = new JSONObject();
                try {
                    jsonObject.put("code", Base64.encodeToString(face.getFeatureData(), Base64.DEFAULT));
                    callbackContext.success(jsonObject);
                } catch (JSONException e) {
                    e.printStackTrace();
                    callbackContext.error(e.getMessage());
                }
            } catch (ArcFaceException e) {
                e.printStackTrace();
                callbackContext.error(e.getMessage());
            }
        } else {
            callbackContext.error(ArcFaceErrorCode.INVALID_PARAMETER);
        }
    }

    /**
     * 对比人脸特征码
     *
     * @param ref             注册的人脸特征码 Base64加密后的数据
     * @param input           要识别的人脸特征码 Base64位加密后的数据
     * @param callbackContext
     */
    private void facePairMatching(String ref, String input, CallbackContext callbackContext) {
        try {
            JSONObject jsonObject = new JSONObject();
            AFR_FSDKFace refB = ArcFaceUtils.getFaceCode(ref);
            AFR_FSDKFace inputB = ArcFaceUtils.getFaceCode(input);
            AFR_FSDKMatching source = ArcFaceUtils.facePairMatching(refB, inputB);
            jsonObject.put("source", source.getScore());
            callbackContext.success(jsonObject);
        } catch (ArcFaceException e) {
            e.printStackTrace();
            callbackContext.error(e.getMessage());
        } catch (JSONException e) {
            e.printStackTrace();
            callbackContext.error(e.getMessage());
        }


    }

    /**
     * 查找相似人脸
     *
     * @param image           base64
     * @param count           返回的数据个数（相似率太低的时候返回多个用于选择）
     * @param callbackContext
     */
    private void searchFace(String image, int count, final CallbackContext callbackContext) {

        try {
            ArcFaceUtils.getFaceEntities(context, image, count, new ArcFaceListener() {
                @Override
                public void onFaceSearchFinish(List<FaceEntity> faceEntityList) {
                    JSONArray jsonArray = new JSONArray();
                    jsonArray.put(faceEntityList);
                    JSONObject jsonObject = new JSONObject();
                    try {
                        jsonObject.put("data", jsonArray);
                        callbackContext.success(jsonObject);
                    } catch (JSONException e) {
                        e.printStackTrace();
                        callbackContext.error(e.getMessage());
                    }
                }

            });
        } catch (ArcFaceException e) {
            callbackContext.error(ErrorMessage.createErrorMessage(e.getErrorCode(), e.getMessage()));
        }
    }

    private void upDateDataBase(String sqlDirectory, final CallbackContext callbackContext) {
        Uri sqlDirectoryUri = getUriForArg(sqlDirectory);
        CordovaResourceApi resourceApi = webView.getResourceApi();
        File sqlDirectoryFile = resourceApi.mapUriToFile(sqlDirectoryUri);
        if (sqlDirectoryFile == null || (!sqlDirectoryFile.exists() && !sqlDirectoryFile.mkdirs())) {
            String errorMessage = "SQL_EXECUTE_ERROR";
            callbackContext.error(ErrorMessage.createErrorMessage(4, "SQL_EXECUTE_ERROR"));
            return;
        }
        if (sqlDirectoryFile.isDirectory()) {
            File[] files = sqlDirectoryFile.listFiles();
            IFaceDao faceDao = FaceDao.newInitialize(webView.getContext().getApplicationContext());
            for (File file : files) {
                faceDao.execute(file);
            }
        } else {
            callbackContext.error(ErrorMessage.createErrorMessage(4, "SQL_EXECUTE_ERROR"));
        }
        callbackContext.success();
    }

    private Uri getUriForArg(String arg) {
        CordovaResourceApi cordovaResourceApi = webView.getResourceApi();
        Uri temTraget = Uri.parse(arg);
        return cordovaResourceApi.remapUri(temTraget.getScheme() != null ? temTraget : Uri.fromFile(new File(arg)));
    }


    /**
     * 删除相关的人脸
     *
     * @param id
     * @param callbackContext
     */
    private void deleteFace(int id, CallbackContext callbackContext) {
        FaceDao faceDao = new FaceDao(context);
        faceDao.deleteEntity(id);
    }

    /**
     * 注册人脸
     *
     * @param remarks
     * @param imageData
     * @param callbackContext
     */
    private void updateOrRegisterFace(int userId, int groupId, String imageData, String remarks, CallbackContext callbackContext) {
        if (userId < 0 || groupId < 0 || !(imageData != null && imageData.length() > 0)) {
            callbackContext.error(ErrorMessage.createErrorMessage(0x000b, "INVALID_PARAMETER"));
        } else {
            try {
                AFR_FSDKFace face = ArcFaceUtils.getFaceCode(imageData);
                if (face != null) {
                    FaceDao faceDao = FaceDao.newInitialize(context.getApplicationContext());
                    FaceEntity faceEntity = faceDao.findEntityById(userId, groupId);
                    String name = "arcface_" + new Date().getTime() + ".jpg";
                    faceEntity.setPicName(name);
                    faceEntity.setRemark(remarks);
                    faceEntity.setCode(Base64.encodeToString(face.getFeatureData(), Base64.DEFAULT));
                    faceEntity.setGroupId(groupId);
                    if (faceEntity.getCreateTime() == 0) {
                        faceEntity.setCreateTime(new Date().getTime());
                    } else {
                        faceEntity.setUpdateTime(new Date().getTime());
                    }
                    faceEntity.setUserId(userId);
                    faceDao.insertUpdateOrEntity(faceEntity);
                    callbackContext.success();
                } else {
                    callbackContext.error(ErrorMessage.createErrorMessage(0x000c, "NO_FACE_IN"));
                }
            } catch (ArcFaceException e) {
                e.printStackTrace();
                callbackContext.error(ErrorMessage.createErrorMessage(e.getErrorCode(), e.getMessage()));
            }


        }
    }

    private boolean hasReadPermission() {
        return cordova.hasPermission(Manifest.permission.READ_EXTERNAL_STORAGE);
    }

    private boolean hasWritePermission() {
        return cordova.hasPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE);
    }


    /*
     * Handle the response
     */
    public void onRequestPermissionResult(int requestCode, String[] permissions,
                                          int[] grantResults) throws JSONException {

        final PendingRequests.Request req = pendingRequests.getAndRemove(requestCode);
        if (req != null) {
            for (int r : grantResults) {
                if (r == PackageManager.PERMISSION_DENIED) {
                    req.getCallbackContext().sendPluginResult(new PluginResult(PluginResult.Status.ERROR, SECURITY_ERR));
                    return;
                }
            }
            arcFaceExecute(req.getAction(), req.getRawArgs(), req.getCallbackContext());
        } else {
            LOG.d(LOG_TAG, "Received permission callback for unknown request code");
        }
    }

}
