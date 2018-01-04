package com.contron.cordova.arcface.db;

import com.contron.cordova.arcface.bean.FaceEntity;

import java.io.File;
import java.util.List;

/**
 * Created by liweifa on 2017/7/25.
 */

public interface IFaceDao extends IDaoBasicDao {

    void deleteEntity(int id);

    FaceEntity findEntityById(int userId, int groupId);

    void insertUpdateOrEntity(FaceEntity entity);

    void execute(final File sqlFile);


}
