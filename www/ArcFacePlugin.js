var exec = require('cordova/exec');

var arc_face = {
	executeData : function(zipFile,outputDirectory,success,error){
		exec(success,error,"ArcFacePlugin","executeData",[zipFile,outputDirectory]);
	},
	unZipFile : function(zipFile,outputDirectory,clearOld,success,error){
		exec(success,error,"ArcFacePlugin","unZipFile",[zipFile,outputDirectory,clearOld]);
	},
	executeSqlFile : function(sqlDircetory,success,error){
		exec(success,error,"ArcFacePlugin","executeSqlFile",[sqlDircetory]);
	},
	getFaceCode : function(image, success, error) {
	    exec(success, error, "ArcFacePlugin", "getFaceCode", [image]);
	},
	facePairMatching : function(ref,input,success,error){
		exec(success,error,"ArcFacePlugin","facePairMatching",[ref,input]);
	},
	searchFace : function(ref,count,success,error){
		exec(success,error,"ArcFacePlugin","searchFace",[ref,count]);
	},
	registerFace : function(userId,groupId,imagePath,remark,success,error){
		exec(success,error,"ArcFacePlugin","registerFace",[userId,groupId,imagePath,remark]);
	},
	deleteFace : function(userId,success,error){
		exec(success,error,"ArcFacePlugin","deleteFace",[userId]);
	}	

};

module.exports = arc_face;
