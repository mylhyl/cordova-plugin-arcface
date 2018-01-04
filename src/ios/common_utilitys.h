

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "amcomdef.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef unsigned char BYTE;
#define SafeArrayFree(p) {if ((p)) free(p); (p) = NULL;}
#define LINE_BYTES(Width, BitCt)    (((int)(Width) * (BitCt) + 31) / 32 * 4)


void RGBA8888ToBGR(unsigned char* pRGBA, int width, int height, int pitch, unsigned char* pBGR);
void BGRA8888ToBGR(unsigned char* pBGRA, int width, int height, int pitch,unsigned char* pBGR);
void BGRAToRGBA(unsigned char* pBGRA, int width, int height, int pitch, unsigned char* pRGBA);
void BGRToNV21(unsigned char *pBGR, int nW, int nH, unsigned char *pYUVY,
               int lYStride, unsigned char *pYUVUV, int lUVStride);
//void NV21ToBGR(unsigned char *pYUVY, int lYStride, unsigned char *pYUVUV,
//               int lUVStride, int nW, int nH, unsigned char *pBGR);
//void BGR2BGRA8888(unsigned char* pBGR, int width, int height, unsigned char* pBGR2);
void BGRCopyToBGRA(unsigned char* pBGR, int cutWidth, int cutHeight, unsigned char* pBGRA, int width, int height, int pitch);
void DrawRect(BYTE* pBuf, int nWidth, int nHeight, int nPitch, MRECT * rt, int color);
void DrawText(unsigned char* pBGR, int width, int height, int pitch,wchar_t* text, char* freetype, MPOINT pt, int r, int g, int b,int fontSize);
void Rotate_bgr(unsigned char* pSrcBGR, int width, int height, unsigned char* pDstBGR, int angle);
//void Flip_bgra(unsigned char* pSrcBGRA, int width, int height, unsigned char* pDstBGRA);
void cutImage(unsigned char* pSrcBGRA,int width,int height,unsigned char* pCutBGRA, int cutWidth,int cutHeight);
void Flip_horizontal_bgra(unsigned char* pSrcBGRA, int width, int height, int pitch, unsigned char* pDstBGRA);
void Flip_vertical_bgra(unsigned char* pSrcBGRA, int width, int height, int pitch, unsigned char* pDstBGRA);    
#define	yuv_shift		14
#define	yuv_fix(x)		(int)((x) * (1 << (yuv_shift)) + 0.5f)
#define	yuv_descale(x)	(((x) + (1 << ((yuv_shift)-1))) >> (yuv_shift))
#define	yuv_prescale(x)	((x) << yuv_shift)

#define	yuvYr	yuv_fix(0.299f)
#define	yuvYg	yuv_fix(0.587f)
#define	yuvYb	yuv_fix(0.114f)
#define	yuvCr	yuv_fix(0.713f)
#define	yuvCb	yuv_fix(0.564f)

#define	yuvRCr	yuv_fix(1.403f)
#define	yuvGCr	(-yuv_fix(0.714f))
#define	yuvGCb	(-yuv_fix(0.344f))
#define	yuvBCb	yuv_fix(1.773f)

#define	ET_CAST_8U(t)		(BYTE)(!((t) & ~255) ? (t) : (t) > 0 ? 255 : 0)
#define ET_YUV_TO_R(y,v)	(BYTE)(ET_CAST_8U(yuv_descale((y) + yuvRCr * (v))))
#define ET_YUV_TO_G(y,u,v)	(BYTE)(ET_CAST_8U(yuv_descale((y) + yuvGCr * (v) + \
yuvGCb * (u))))
#define ET_YUV_TO_B(y,u)	(BYTE)(ET_CAST_8U(yuv_descale((y) + yuvBCb * (u))))

#define ET_RGB_TO_Y(r,g,b)	(int)(yuv_descale((b) * yuvYb + (g) * yuvYg + \
(r) * yuvYr))
#define ET_RGB_TO_U(y,b)	(int)(yuv_descale(((b) - (y)) * yuvCb) + 128)
#define ET_RGB_TO_V(y,r)	(int)(yuv_descale(((r) - (y)) * yuvCr) + 128)
 
#ifdef __cplusplus
}
#endif

@interface common_utilitys : NSObject
+ (unsigned char *) bitmapFromImage: (UIImage *) image : (int) orient;
+ (UIImage *) imageWithBits: (unsigned char *) bits withSize: (CGSize) size;

@end
