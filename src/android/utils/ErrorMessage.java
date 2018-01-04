package com.contron.cordova.arcface.utils;

import org.json.JSONException;
import org.json.JSONObject;

/**
 * Created by liweifa on 2017/12/19.
 */

public class ErrorMessage {

    public static JSONObject createErrorMessage(int code, String message) {
        JSONObject jsonObject = new JSONObject();
        try {
            jsonObject.put("code", code);
            jsonObject.put("message", message);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return jsonObject;
    }
}
