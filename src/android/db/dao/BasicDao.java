package com.contron.cordova.arcface.db.dao;

import android.content.Context;
import android.database.sqlite.SQLiteDatabase;
import android.os.Build;


import com.contron.cordova.arcface.db.IDaoBasicDao;



/**
 * Created by hupei on 2015/12/14 13:08.
 */
class BasicDao implements IDaoBasicDao {

    protected  SQLiteDatabase database;
    private boolean allowTransaction = true;

    public BasicDao(Context context) {
        DbHelper dbHelper=new DbHelper(context);
        this.database = dbHelper.getWritableDatabase();
    }


    public void beginTransaction() {
        if (allowTransaction) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN && database
                    .isWriteAheadLoggingEnabled()) {
                database.beginTransactionNonExclusive();
            } else {
                database.beginTransaction();
            }
        }
    }

    public SQLiteDatabase getDatabase() {
        return database;
    }



    public void endTransaction() {
        if (allowTransaction)
            database.endTransaction();
    }



}
