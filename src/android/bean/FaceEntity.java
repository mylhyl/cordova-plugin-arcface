package com.contron.cordova.arcface.bean;


/**
 * Created by liweifa on 2017/7/25.
 */

import org.json.JSONException;
import org.json.JSONObject;

import java.io.Serializable;
import java.util.Date;

/**
 * 人脸库比表
 */
public class FaceEntity implements Serializable {
    public static final String TABLE_NAME = "face";
    public static final String COLUMN_NAME_USER_ID = "userId";
    public static final String COLUMN_NAME_GROUP_ID = "groupId";
    public static final String COLUMN_NAME_PIC_NAME = "picName";
    public static final String COLUMN_NAME_CODE = "code";
    public static final String COLUMN_NAME_SOURCE = "source";
    public static final String COLUMN_NAME_REMARK = "remark";
    public static final String COLUMN_NAME_CREATE_TIME = "createTime";
    public static final String COLUMN_NAME_UPDATE_TIME = "updateTime";

    /**
     * 用户id主键
     * 非自增主键
     */
    private int userId;
    /**
     * 分组id
     * 非自增主键
     */
    private int groupId;
    /**
     * 图片名
     */
    private String picName;
    /**
     * 特征码
     */
    private String code;
    /**
     * 备注
     */
    private String remark;
    /**
     * 置信率
     * 不保存在数据库 只在返回数据中
     */
    private float source;
    /**
     * 创建时间
     */
    private long createTime;
    /**
     * 修改时间
     */
    private long updateTime;

    public FaceEntity() {
    }


    public FaceEntity(int userId, int groupId, String picName, String code, String remark) {
        this.userId = userId;
        this.groupId = groupId;
        this.picName = picName;
        this.code = code;
        this.remark = remark;
    }

    public int getUserId() {
        return userId;
    }

    public void setUserId(int userId) {
        this.userId = userId;
    }

    public int getGroupId() {
        return groupId;
    }

    public void setGroupId(int groupId) {
        this.groupId = groupId;
    }

    public String getPicName() {
        return picName;
    }

    public void setPicName(String picName) {
        this.picName = picName;
    }

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
    }

    public String getRemark() {
        return remark;
    }

    public void setRemark(String remark) {
        this.remark = remark;
    }

    public float getSource() {
        return source;
    }

    public void setSource(float source) {
        this.source = source;
    }

    public long getCreateTime() {
        return createTime;
    }

    public void setCreateTime(long createTime) {
        this.createTime = createTime;
    }

    public long getUpdateTime() {
        return updateTime;
    }

    public void setUpdateTime(long updateTime) {
        this.updateTime = updateTime;
    }

    @Override
    public String toString() {
        JSONObject jsonObject = new JSONObject();
        try {
            jsonObject.put(COLUMN_NAME_USER_ID, getUserId());
            jsonObject.put(COLUMN_NAME_GROUP_ID, getGroupId());
            jsonObject.put(COLUMN_NAME_PIC_NAME, getPicName());
            jsonObject.put(COLUMN_NAME_CODE, getCode());
            jsonObject.put(COLUMN_NAME_SOURCE, getSource());
            jsonObject.put(COLUMN_NAME_REMARK, getRemark());
            jsonObject.put(COLUMN_NAME_CREATE_TIME, getCreateTime());
            jsonObject.put(COLUMN_NAME_UPDATE_TIME, getUpdateTime());
            return jsonObject.toString();
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return super.toString();
    }
}
