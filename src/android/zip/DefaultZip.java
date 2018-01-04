package com.contron.cordova.arcface.zip;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;


import org.apache.cordova.CallbackContext;

import android.net.Uri;
import android.util.Log;

import com.contron.cordova.arcface.zip.IZip;


/**
 * Created by liweifa on 2017/12/1.
 */

public class DefaultZip implements IZip {

    private static final String LOG_TAG = "DefaultZip";



    public DefaultZip() {

    }

    /**
     * 解压缩文件
     */
    @Override
    public boolean unzipSync(String zipDirectory, String outputDirectory,final boolean clearOld, CallbackContext callbackContext) {

        if (clearOld) {
            File file = new File(outputDirectory);
            if (file.isDirectory()) {
                File[] files = file.listFiles();
                for (File f : files) {
                    f.delete();
                }
            }
        }
        InputStream inputStream = null;
        try {
            // Since Cordova 3.3.0 and release of File plugins, files are accessed via cdvfile://
            // Accept a path or a URI for the source zip.
            Uri zipUri = getUriForArg(zipDirectory);
            Uri outputUri = getUriForArg(outputDirectory);


            File zipFile = new File(zipUri.getPath());
            if (!zipFile.exists()) {
                String errorMessage = "DefaultZip file does not exist";
                callbackContext.error(errorMessage);
                Log.e(LOG_TAG, errorMessage);
                return false;
            }

            File outputDir = new File(outputUri.getPath());
            outputDirectory = outputDir.getAbsolutePath();
            outputDirectory += outputDirectory.endsWith(File.separator) ? "" : File.separator;
            if (!outputDir.exists() && !outputDir.mkdirs()) {
                String errorMessage = "Could not create output directory";
                callbackContext.error(errorMessage);
                Log.e(LOG_TAG, errorMessage);
                return false;
            }
            inputStream = new BufferedInputStream(new FileInputStream(zipFile));
            // The inputstream is now pointing at the start of the actual zip file content.
            ZipInputStream zis = new ZipInputStream(inputStream);
            inputStream = zis;

            ZipEntry ze;
            byte[] buffer = new byte[32 * 1024];
            boolean anyEntries = false;

            while ((ze = zis.getNextEntry()) != null) {
                anyEntries = true;
                String compressedName = ze.getName();

                if (ze.isDirectory()) {
                    File dir = new File(outputDirectory + compressedName);
                    dir.mkdirs();
                } else {
                    File file = new File(outputDirectory + compressedName);
                    file.getParentFile().mkdirs();
                    if (file.exists() || file.createNewFile()) {
                        Log.w("DefaultZip", "extracting: " + file.getPath());
                        FileOutputStream fout = new FileOutputStream(file);
                        int count;
                        while ((count = zis.read(buffer)) != -1) {
                            fout.write(buffer, 0, count);
                        }
                        fout.close();
                    }

                }
                zis.closeEntry();
            }


            if (anyEntries) {
//                callbackContext.success();
            } else {
                callbackContext.error("Bad zip file");
            }
        } catch (Exception e) {
            String errorMessage = "An error occurred while unzipping.";
            callbackContext.error(errorMessage);
            Log.e(LOG_TAG, errorMessage, e);
        } finally {
            if (inputStream != null) {
                try {
                    inputStream.close();
                } catch (IOException e) {
                }
            }
        }
        return true;
    }

    @Override
    public boolean zipSync(boolean clearOld, CallbackContext callbackContext) {
        return false;
    }


    //
    private Uri getUriForArg(String arg) {
        Uri tmpTarget = Uri.parse(arg);
        return tmpTarget.getScheme() != null ? tmpTarget : Uri.fromFile(new File(arg));
    }

}
