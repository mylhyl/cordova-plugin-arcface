package com.contron.cordova.arcface.db.dao;

import android.content.Context;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;

import com.contron.cordova.arcface.bean.FaceEntity;

/**
 * SQLiteHeper
 */
final class DbHelper extends SQLiteOpenHelper {
    public static final int DATABASE_VERSION = 1;
    public static final String DATABASE_NAME = "face.db";

    public DbHelper(Context context) {
        super(context, DATABASE_NAME, null, DATABASE_VERSION);
    }

    @Override
    public void onCreate(SQLiteDatabase db) {
        String SQL_CREATE_ENTRIES = "CREATE TABLE IF NOT EXISTS " + FaceEntity.TABLE_NAME + " (" +
                " " + FaceEntity.COLUMN_NAME_USER_ID + "  INTEGER NOT NULL," +
                " " + FaceEntity.COLUMN_NAME_GROUP_ID + "  INTEGER NOT NULL," +
                " " + FaceEntity.COLUMN_NAME_PIC_NAME + "  TEXT," +
                " " + FaceEntity.COLUMN_NAME_CODE + "  TEXT," +
                " " + FaceEntity.COLUMN_NAME_REMARK + "  TEXT," +
                " " + FaceEntity.COLUMN_NAME_CREATE_TIME + "  TEXT," +
                " " + FaceEntity.COLUMN_NAME_UPDATE_TIME + "  TEXT," +
                " PRIMARY KEY (\"" + FaceEntity.COLUMN_NAME_USER_ID + "\", \"" + FaceEntity.COLUMN_NAME_GROUP_ID + "\")" +
                ")";
        db.execSQL(SQL_CREATE_ENTRIES);
    }

    @Override
    public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {

    }
}
