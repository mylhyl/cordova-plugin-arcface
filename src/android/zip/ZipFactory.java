package com.contron.cordova.arcface.zip;

import android.text.TextUtils;

/**
 * Created by liweifa on 2017/12/13.
 */

public class ZipFactory {
    private static ZipFactory zipFactory;

    public static ZipFactory newInstance() {
        synchronized (ZipFactory.class) {
            if (zipFactory == null) {
                synchronized (ZipFactory.class) {
                    zipFactory = new ZipFactory();
                }
            }
        }
        return zipFactory;
    }

    public IZip createZip(String zipDirectory, String outputDirectory) {
        IZip zip = null;
        if (!TextUtils.isEmpty(zipDirectory) && zipDirectory.endsWith("zip")) {
            zip = new DefaultZip();
        } else if (!TextUtils.isEmpty(zipDirectory) && zipDirectory.endsWith("7z")) {
            zip = new SevenZip();
        }
        return zip;
    }
}
