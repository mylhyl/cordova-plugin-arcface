package com.contron.cordova.arcface.utils;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

/**
 * Created by liweifa on 2017/12/4.
 */

public class FileUtil {

    /**
     * 获取文件里面的所有数据，以某个分割符分割
     * @param file
     * @param split 分割符
     * @return
     */
    public static List<String> decomposeFile(File file, String split) {

        List<String> strings = new ArrayList<String>();
        String s = "";
        try {
            InputStream in = new FileInputStream(file);
            byte[] b = new byte[(int) file.length()];
            in.read(b, 0, (int) file.length());
            s = new String(b);
            strings.addAll(Arrays.asList(s.split(split)));
            in.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
        return strings;
    }

    /**
     * 获取文件名，去掉后缀的
     * @param file
     * @return
     */
    public static String getFileNameExceptSuffix(File file) {
        String name = file.getName();
        int spotIndex = name.lastIndexOf(".");
        return spotIndex == -1 ? name : name.substring(0, spotIndex);
    }


}
