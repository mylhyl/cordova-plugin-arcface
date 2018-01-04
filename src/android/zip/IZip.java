package com.contron.cordova.arcface.zip;

import org.apache.cordova.CallbackContext;

/**
 * Created by liweifa on 2017/12/13.
 */

public interface IZip {
    /**
     * 解压缩
     * @param zipDirectory
     * @param outputDirectory
     * @param clearOld
     * @param callbackContext
     * @return
     */
    boolean unzipSync(   String zipDirectory, String outputDirectory,final boolean clearOld, CallbackContext callbackContext);

    /**
     * 压缩
     * @param clearOld
     * @param callbackContext
     * @return
     */
    boolean zipSync( final boolean clearOld, CallbackContext callbackContext);
}
