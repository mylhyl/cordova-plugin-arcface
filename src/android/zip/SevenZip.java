package com.contron.cordova.arcface.zip;

import android.net.Uri;
import android.util.Log;

import com.contron.cordova.arcface.utils.ErrorMessage;

import org.apache.commons.compress.archivers.sevenz.SevenZArchiveEntry;
import org.apache.commons.compress.archivers.sevenz.SevenZFile;
import org.apache.cordova.CallbackContext;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

/**
 * Created by liweifa on 2017/12/13.
 */

public class SevenZip implements IZip {
    private static final String LOG_TAG = "SevenZip";


    public SevenZip() {
    }

    private byte[] buffer = new byte[32 * 1024];

    @Override
    public boolean unzipSync(String zipDirectory, String outputDirectory, boolean clearOld, CallbackContext callbackContext) {


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

            boolean anyEntries = false;
            File zipFile = new File(zipUri.getPath());
            if (!zipFile.exists()) {
                if (callbackContext != null) {
                    callbackContext.error(ErrorMessage.createErrorMessage(1,"NO_FOUND_FILE"));
                }

                return false;
            }

            File outputDir = new File(outputUri.getPath());
            outputDirectory = outputDir.getAbsolutePath();
            outputDirectory += outputDirectory.endsWith(File.separator) ? "" : File.separator;
            if (!outputDir.exists() && !outputDir.mkdirs()) {

                if (callbackContext != null) {
                    callbackContext.error(ErrorMessage.createErrorMessage(2,"UNZIPPING_ERROR"));
                }
//                Log.e(LOG_TAG, errorMessage);
                return false;
            }

            SevenZFile sevenZFile = new SevenZFile(zipFile);
            SevenZArchiveEntry entry;
            while ((entry = sevenZFile.getNextEntry()) != null) {
                anyEntries = true;
                String compressedName = entry.getName();
                if (entry.isDirectory()) {
                    File dir = new File(outputDirectory + compressedName);
                    dir.mkdirs();
                } else {
                    File file = new File(outputDirectory + compressedName);
                    file.getParentFile().mkdirs();
                    if (file.exists() || file.createNewFile()) {
//                        Log.w("DefaultZip", "extracting: " + file.getPath());
                        FileOutputStream fout = new FileOutputStream(file);
                        int count;
                        while ((count = sevenZFile.read(buffer)) != -1) {
                            fout.write(buffer, 0, count);
                        }
                        fout.close();
                    }
                }
            }

            if (anyEntries) {
                if (callbackContext != null) {
//                    callbackContext.success();
                }
            } else {
                if (callbackContext != null) {
                    callbackContext.error(ErrorMessage.createErrorMessage(2,"UNZIPPING_ERROR"));
                }
            }
        } catch (Exception e) {
            if (callbackContext != null) {
                callbackContext.error(ErrorMessage.createErrorMessage(2,"UNZIPPING_ERROR"));
            }
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
//        SevenZFile sevenZFile = new SevenZFile();
        return false;
    }


    //

    private Uri getUriForArg(String arg) {
        Uri tmpTarget = Uri.parse(arg);
        return tmpTarget.getScheme() != null ? tmpTarget : Uri.fromFile(new File(arg));
    }
}
