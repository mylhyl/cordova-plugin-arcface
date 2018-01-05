package com.contron.cordova.arcface.db.dao;

import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.text.TextUtils;

import com.contron.cordova.arcface.bean.FaceEntity;
import com.contron.cordova.arcface.db.IFaceDao;
import com.contron.cordova.arcface.utils.FileUtil;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

/**
 * Created by liweifa on 2017/7/25.
 */

public class FaceDao extends BasicDao implements IFaceDao {
    private static FaceDao faceDao;
    private static final Object object = new Object();

    public FaceDao(Context context) {
        super(context);
    }

    public static FaceDao newInitialize(Context context) {
        synchronized (object) {
            if (faceDao == null) {
                synchronized (object) {
                    faceDao = new FaceDao(context);
                }
            }
        }

        return faceDao;
    }

    @Override
    public void deleteEntity(int id) {
        String selection;
        selection = FaceEntity.COLUMN_NAME_USER_ID + " = ?";
        String[] selectionArgs = {String.valueOf(id)};
        database.delete(FaceEntity.TABLE_NAME, selection, selectionArgs);
    }

    @Override
    public FaceEntity findEntityById(int userId, int groupId) {
        FaceEntity entity = new FaceEntity();
        String[] projection = {
                FaceEntity.COLUMN_NAME_USER_ID,
                FaceEntity.COLUMN_NAME_GROUP_ID,
                FaceEntity.COLUMN_NAME_PIC_NAME,
                FaceEntity.COLUMN_NAME_CODE,
                FaceEntity.COLUMN_NAME_REMARK,
                FaceEntity.COLUMN_NAME_CREATE_TIME,
                FaceEntity.COLUMN_NAME_UPDATE_TIME
        };
        String selection = FaceEntity.COLUMN_NAME_USER_ID + " = ?& " + FaceEntity.COLUMN_NAME_GROUP_ID + " =?";
        String[] selectionArgs = {String.valueOf(userId), String.valueOf(groupId)};

        Cursor cursor = database.query(FaceEntity.TABLE_NAME, projection, selection, selectionArgs, null, null, null);
        if (cursor.moveToFirst()) {
            entity.setUserId(cursor.getInt(cursor.getColumnIndex(FaceEntity.COLUMN_NAME_USER_ID)));
            entity.setGroupId(cursor.getInt(cursor.getColumnIndex(FaceEntity.COLUMN_NAME_GROUP_ID)));
            entity.setPicName(cursor.getString(cursor.getColumnIndex(FaceEntity.COLUMN_NAME_PIC_NAME)));
            entity.setCode(cursor.getString(cursor.getColumnIndex(FaceEntity.COLUMN_NAME_CODE)));
            entity.setRemark(cursor.getString(cursor.getColumnIndex(FaceEntity.COLUMN_NAME_REMARK)));
            entity.setCreateTime(cursor.getLong(cursor.getColumnIndex(FaceEntity.COLUMN_NAME_CREATE_TIME)));
            entity.setUpdateTime(cursor.getLong(cursor.getColumnIndex(FaceEntity.COLUMN_NAME_UPDATE_TIME)));
        }
        cursor.close();

        return entity;
    }

    @Override
    public void insertUpdateOrEntity(FaceEntity entity) {
        ContentValues values = new ContentValues();
        values.put(FaceEntity.COLUMN_NAME_USER_ID, entity.getUserId());
        values.put(FaceEntity.COLUMN_NAME_GROUP_ID, entity.getGroupId());
        if (entity.getPicName() != null) {
            values.put(FaceEntity.COLUMN_NAME_PIC_NAME, entity.getPicName());
        }
        if (entity.getCode() != null) {
            values.put(FaceEntity.COLUMN_NAME_CODE, entity.getCode());
        }
        values.put(FaceEntity.COLUMN_NAME_REMARK, entity.getRemark());
        values.put(FaceEntity.COLUMN_NAME_CREATE_TIME, entity.getCreateTime());
        values.put(FaceEntity.COLUMN_NAME_UPDATE_TIME, entity.getUpdateTime());
//        database.insert(FaceEntity.TABLE_NAME, null, values);
        database.insertWithOnConflict(FaceEntity.TABLE_NAME, FaceEntity.COLUMN_NAME_REMARK, values, SQLiteDatabase.CONFLICT_REPLACE);
    }

    @Override
    public void execute(final File sqlFile) {
        List<String> sqlList = FileUtil.decomposeFile(sqlFile, ";");
        for (int i = 0; i < sqlList.size(); i++) {
            String sql = sqlList.get(i).trim();
            if (!TextUtils.isEmpty(sql)) {
                faceDao.getDatabase().execSQL(sql);
            }
        }
    }
}
