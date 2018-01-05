import { Injectable } from "@angular/core";
import { FileServ } from "./FileServ";
import { HttpServ } from "./HttpServ";
import { CameraServ } from "./CameraServ";

declare let ArcFace;

const INVALID_PARAMETER = "无效的参数";
const NO_FACE_IN = "未识别到人脸";
const NO_FACE_REGISTERED = "图像未注册";
const CALL_ARCFACE_FAIL = "调用人脸库失败：";

@Injectable()
export class ArcFaceServ {
  constructor(
    private file: FileServ,
    private http: HttpServ,
    private camera: CameraServ
  ) {}

  /**
   * 下载并初始化数据
   * 成功 string：OK
   * 失败 string：错误信息
   * @param url 服务器7z压缩文件路径
   */
  initForDownload(url: string) {
    let cacheDir = this.file.getCacheDir();
    let zipPath = cacheDir + "arcface.7z";
    return new Promise((resolve, reject) => {
      this.http
        .downloadFile(url, {}, {}, zipPath)
        .then(res => {
          this.initData(zipPath, cacheDir)
            .then(res => {
              resolve(res);
            })
            .catch(err => {
              reject(err);
            });
        })
        .catch(err => {
          reject(err.msg);
        });
    });
  }

  /**
   * 初始化数据
   * 成功 string：OK
   * 失败 string：错误信息
   * @param srcFilePath 待解压的7z文件路径
   * @param destDir 解压到的目录
   */
  initData(srcFilePath: string, destDir: string) {
    return new Promise((resolve, reject) => {
      ArcFace.executeData(
        srcFilePath,
        destDir,
        res => {
          resolve(res);
        },
        err => {
          switch (err.code) {
            case 1:
              reject("解压文件不存在！");
              break;
            case 2:
              reject("解压文件出错！");
              break;
            case 3:
              reject("解压文件格式不正确！");
              break;
            case 4:
              reject("数据库脚本执行出错！");
              break;
            default:
              break;
          }
        }
      );
    });
  }

  /**
   * 拍照验证人验
   * 成功 jsonObject：{imageData, faceData}
   *      imageData：base64图像
   *      faceData:人脸对象[{userId, groupId, picName, code, remark, source}]
   * 失败 string：错误信息
   * @param backCount
   */
  verificationForCamera(backCount: number): Promise<any> {
    return new Promise((resolve, reject) => {
      this.camera
        .getPicture()
        .then(data => {
          this.verification(data.toString(), backCount)
            .then(res => {
              resolve({ imageData: data.toString(), faceData: res.data });
            })
            .catch(err => {
              reject(err);
            });
        })
        .catch(err => {
          reject(err);
        });
    });
  }

  /**
   * 人脸验证
   * 成功 jsonObject：人脸对象[{userId, groupId, picName, code, remark, source}]
   * 失败 string：错误信息
   * @param imageData 当前人脸图像base64
   * @param backCount 需要返回相似总量
   */
  verification(imageData: string, backCount: number): Promise<any> {
    return new Promise((resolve, reject) => {
      ArcFace.searchFace(
        imageData,
        backCount,
        res => {
          resolve(res.data);
        },
        err => {
          switch (err.code) {
            case 11:
              reject(INVALID_PARAMETER);
              break;
            case 12:
              reject(NO_FACE_IN);
              break;
            case 13:
              reject(NO_FACE_REGISTERED);
              break;
            default:
              reject(CALL_ARCFACE_FAIL + err.code);
              break;
          }
        }
      );
    });
  }

  /**
   * 拍照注册人脸库
   * 成功 string：图像路径
   * 失败 string：错误信息
   * @param userId
   * @param groupId
   * @param remark
   */
  registerForCamera(
    userId: number,
    groupId: number,
    remark: string
  ): Promise<any> {
    return new Promise((resolve, reject) => {
      this.camera
        .getPictureUrl()
        .then(fileUri => {
          this.register(userId, groupId, fileUri, remark)
            .then(res => {
              resolve(fileUri);
            })
            .catch(err => {
              reject(err);
            });
        })
        .catch(err => {
          reject(err);
        });
    });
  }

  /**
   * 注册人脸库
   * 成功 string：OK
   * 失败 string：错误信息
   * @param userId 用户ID
   * @param groupId 分组ID
   * @param photoPath 图像绝对路径
   * @param remark 备注
   */
  register(userId: number, groupId: number, photoPath: string, remark: string) {
    return new Promise((resolve, reject) => {
      ArcFace.registerFace(
        userId,
        groupId,
        photoPath,
        remark,
        res => {
          resolve(res);
        },
        err => {
          switch (err.code) {
            case 11:
              reject(INVALID_PARAMETER);
              break;
            case 12:
              reject(NO_FACE_IN);
              break;
            default:
              reject(CALL_ARCFACE_FAIL + err.code);
              break;
          }
        }
      );
    });
  }
}
