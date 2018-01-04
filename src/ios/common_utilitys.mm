

#import "common_utilitys.h"
#import <CoreGraphics/CoreGraphics.h>

#define TRIMBYTE(x)	(MUInt8)((x)&(~255)?((-(x))>>31):(x))

CGContextRef CreateARGBBitmapContext (CGSize size)
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	if (colorSpace == NULL)
    {
        fprintf(stderr, "Error allocating color space\n");
        return NULL;
    }
	
    void *bitmapData = malloc(size.width * size.height * 4);
    if (bitmapData == NULL)
    {
        fprintf (stderr, "Error: Memory not allocated!");
        CGColorSpaceRelease(colorSpace);
        return NULL;
    }
	
    CGContextRef context = CGBitmapContextCreate (bitmapData, size.width, size.height, 8, size.width * 4, colorSpace, kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace );
    if (context == NULL)
    {
        fprintf (stderr, "Error: Context not created!");
        free (bitmapData);
		return NULL;
    }
	
    return context;
}

//rgba to bgr
void RGBA8888ToBGR(unsigned char* pRGBA, int width, int height,int pitch, unsigned char* pBGR)
{
    int iSrcXStride = LINE_BYTES(width, 24);
    int iSrcXStride2 = pitch;//LINE_BYTES(width, 32);
    int i, j;
    for(i = 0; i < height; i++)
    {
        for(j = 0; j < width; j++)
        {
            pBGR[i*iSrcXStride+j*3  ]=pRGBA[i*iSrcXStride2+j*4+2];
            pBGR[i*iSrcXStride+j*3+1]=pRGBA[i*iSrcXStride2+j*4+1];
            pBGR[i*iSrcXStride+j*3+2] = pRGBA[i*iSrcXStride2+j*4];
        }
    }
}
//bgra to bgr
void BGRA8888ToBGR(unsigned char* pBGRA, int width, int height, int pitch, unsigned char* pBGR)
{
    int iSrcXStride = LINE_BYTES(width, 24);
    int iSrcXStride2 = pitch;//LINE_BYTES(width, 32);
    int i, j;
    for(i = 0; i < height; i++)
    {
        for(j = 0; j < width; j++)
        {
            pBGR[i*iSrcXStride+j*3  ]=pBGRA[i*iSrcXStride2+j*4];//crash
            pBGR[i*iSrcXStride+j*3+1]=pBGRA[i*iSrcXStride2+j*4+1];
            pBGR[i*iSrcXStride+j*3+2] = pBGRA[i*iSrcXStride2+j*4+2];
        }
    }
}
void BGRToNV21(unsigned char *pBGR, int nW, int nH, unsigned char *pYUVY,
               int lYStride, unsigned char *pYUVUV, int lUVStride)
{
    unsigned int x;
    int y;
    unsigned char *pbSrcX = pBGR;
    unsigned char *pbDstY = pYUVY;
    unsigned char *pbDstUV = pYUVUV;
    
    int iSrcXStride = LINE_BYTES(nW, 24);
    int iDstYStride = lYStride;
    int iDstUVStride = lUVStride;
    int iSrcXDif;
    int iDstYDif;
    int iDstUVDif;
    
    iSrcXDif = iSrcXStride - (nW * 3);
    iDstYDif = iDstYStride - nW;
    iDstUVDif = iDstUVStride - nW;
    
    for (y = nH / 2; y; y--)
    {
        for (x = nW / 2; x; x--)
        {
            int r, g, b, y0, y1, y2, y3, cb, cr;
            
            b = pbSrcX[0];
            g = pbSrcX[1];
            r = pbSrcX[2];
            y0 = yuv_descale(b*yuvYb + g*yuvYg + r*yuvYr);
            cb = yuv_descale((b - y0)*yuvCb) + 128;
            cr = yuv_descale((r - y0)*yuvCr) + 128;
            
            b = pbSrcX[3];
            g = pbSrcX[4];
            r = pbSrcX[5];
            y1 = yuv_descale(b*yuvYb + g*yuvYg + r*yuvYr);
            cb += yuv_descale((b - y1)*yuvCb) + 128;
            cr += yuv_descale((r - y1)*yuvCr) + 128;
            
            b = pbSrcX[iSrcXStride  ];
            g = pbSrcX[iSrcXStride+1];
            r = pbSrcX[iSrcXStride+2];
            y2 = yuv_descale(b*yuvYb + g*yuvYg + r*yuvYr);
            cb += yuv_descale((b - y2)*yuvCb) + 128;
            cr += yuv_descale((r - y2)*yuvCr) + 128;
            
            b = pbSrcX[iSrcXStride+3];
            g = pbSrcX[iSrcXStride+4];
            r = pbSrcX[iSrcXStride+5];
            y3 = yuv_descale(b*yuvYb + g*yuvYg + r*yuvYr);
            cb += yuv_descale((b - y3)*yuvCb) + 128;
            cr += yuv_descale((r - y3)*yuvCr) + 128;
            
            pbDstY[0] = ET_CAST_8U(y0);
            pbDstY[1] = ET_CAST_8U(y1);
            pbDstY[iDstYStride  ] = ET_CAST_8U(y2);
            pbDstY[iDstYStride+1] = ET_CAST_8U(y3);
            pbDstUV[0] = ET_CAST_8U(cr>>2);
            pbDstUV[1] = ET_CAST_8U(cb>>2);
            
            pbSrcX += 6;
            pbDstY += 2;
            pbDstUV += 2;
        }
        
        pbSrcX += iSrcXDif + iSrcXStride;
        pbDstY += iDstYDif + iDstYStride;
        pbDstUV += iDstUVDif;
    }
}
void NV21ToBGR(unsigned char *pYUVY, int lYStride, unsigned char *pYUVUV,
               int lUVStride, int nW, int nH, unsigned char *pBGR)
{
    unsigned int x;
    int y;
    unsigned char *pbSrcY = pYUVY;
    unsigned char *pbSrcUV = pYUVUV;
    unsigned char *pbDstX = pBGR;
    
    int iDstXStride = LINE_BYTES(nW, 24);
    int iSrcYStride = lYStride;
    int iSrcUVStride = lUVStride;
    int iDstXDif;
    int iSrcYDif;
    int iSrcUVDif;
    
    iDstXDif = iDstXStride - (nW * 3);
    iSrcYDif = iSrcYStride - nW;
    iSrcUVDif = iSrcUVStride - nW;
    
    for (y = nH / 2; y; y--)
    {
        for (x = nW / 2; x; x--)
        {
            int cr = pbSrcUV[0] - 128;
            int cb = pbSrcUV[1] - 128;
            int y00 = pbSrcY[0];
            int y01 = pbSrcY[1];
            int y10 = pbSrcY[iSrcYStride  ];
            int y11 = pbSrcY[iSrcYStride+1];
            
            y00 = yuv_prescale(y00);
            y01 = yuv_prescale(y01);
            
            pbDstX[2] = ET_YUV_TO_R(y00, cr);
            pbDstX[1] = ET_YUV_TO_G(y00, cb, cr);
            pbDstX[0] = ET_YUV_TO_B(y00, cb);
            pbDstX[5] = ET_YUV_TO_R(y01, cr);
            pbDstX[4] = ET_YUV_TO_G(y01, cb, cr);
            pbDstX[3] = ET_YUV_TO_B(y01, cb);
            
            y10 = yuv_prescale(y10);
            y11 = yuv_prescale(y11);
            
            pbDstX[iDstXStride+2] = ET_YUV_TO_R(y10, cr);
            pbDstX[iDstXStride+1] = ET_YUV_TO_G(y10, cb, cr);
            pbDstX[iDstXStride  ] = ET_YUV_TO_B(y10, cb);
            pbDstX[iDstXStride+5] = ET_YUV_TO_R(y11, cr);
            pbDstX[iDstXStride+4] = ET_YUV_TO_G(y11, cb, cr);
            pbDstX[iDstXStride+3] = ET_YUV_TO_B(y11, cb);
            
            pbDstX += 6;
            pbSrcY += 2;
            pbSrcUV += 2;
        }
        
        pbDstX += iDstXDif + iDstXStride;
        pbSrcY += iSrcYDif + iSrcYStride;
        pbSrcUV += iSrcUVDif;
    }
}
//rgb to rgba
void BGR2BGRA8888(unsigned char* pBGR, int width, int height, unsigned char* pBGR2)
{
    int iSrcXStride = LINE_BYTES(width, 24);
    int iSrcXStride2 = LINE_BYTES(width, 32);
    int i, j;
    for(i = 0; i < height; i++)
    {
        for(j = 0; j < width; j++)
        {
            pBGR2[i*iSrcXStride2+j*4  ]=pBGR[i*iSrcXStride+j*3];
            pBGR2[i*iSrcXStride2+j*4+1]=pBGR[i*iSrcXStride+j*3+1];
            pBGR2[i*iSrcXStride2+j*4+2] = pBGR[i*iSrcXStride+j*3+2];
            //pBGR2[i*iSrcXStride2+j*4+3] = 0;
        }
    }
}

void DrawRect(BYTE* pBuf, int nWidth, int nHeight, int nPitch, MRECT * rt, int color)
{
    int lChannels=3;
    int i;
    BYTE r,g,b;
    if(rt->left<0)
        rt->left = 0;
    if(rt->left>nWidth)
        rt->left=nWidth;
    if(rt->right<0)
        rt->right = 0;
    if(rt->right>nWidth)
        rt->right = nWidth;
    if(rt->top<0)
        rt->top=0;
    if(rt->top>nHeight)
        rt->top=nHeight;
    if(rt->bottom<0)
        rt->bottom=0;
    if(rt->bottom>nHeight)
        rt->bottom=nHeight;
    switch(color)
    {
        case 0://white
            r = 0xFF;
            g = 0xFF;
            b = 0xFF;
            break;
        case 1://red
            r = 0xFF;
            g = 0x00;
            b = 0x00;
            break;
        case 2://green
            r = 0x00;
            g = 0xFF;
            b = 0x00;
            break;
        case 3://yellow
            r = 0xff;
            g = 0xff;
            b = 0x00;
    }
    
    for(i = 0; i< (rt->right-rt->left);i++)
    {
      //  if(i<20 || i>rt->right-rt->left-20)
        {
            pBuf[rt->top*nPitch+(rt->left+i)*lChannels]=b;
            pBuf[rt->top*nPitch+(rt->left+i)*lChannels+1]=g;
            pBuf[rt->top*nPitch+(rt->left+i)*lChannels+2]=r;
            
            pBuf[(rt->bottom-1)*nPitch+(rt->left+i)*lChannels]=b;
            pBuf[(rt->bottom-1)*nPitch+(rt->left+i)*lChannels+1]=g;
            pBuf[(rt->bottom-1)*nPitch+(rt->left+i)*lChannels+2]=r;
            
            pBuf[(rt->top+1)*nPitch+(rt->left+i)*lChannels]=b;
            pBuf[(rt->top+1)*nPitch+(rt->left+i)*lChannels+1]=g;
            pBuf[(rt->top+1)*nPitch+(rt->left+i)*lChannels+2]=r;
            
            pBuf[(rt->bottom-2)*nPitch+(rt->left+i)*lChannels]=b;
            pBuf[(rt->bottom-2)*nPitch+(rt->left+i)*lChannels+1]=g;
            pBuf[(rt->bottom-2)*nPitch+(rt->left+i)*lChannels+2]=r;
        }
        
    }
    for(i=rt->top;i<rt->bottom;i++)
    {
     //   if(i<rt->top+20 || i > rt->bottom-20)
        {
            pBuf[i*nPitch+rt->left*lChannels]=b;
            pBuf[i*nPitch+rt->left*lChannels+1]=g;
            pBuf[i*nPitch+rt->left*lChannels+2]=r;
            
            pBuf[i*nPitch+(rt->right-1)*lChannels]=b;
            pBuf[i*nPitch+(rt->right-1)*lChannels+1]=g;
            pBuf[i*nPitch+(rt->right-1)*lChannels+2]=r;
            
            pBuf[i*nPitch+(rt->left+1)*lChannels]=b;
            pBuf[i*nPitch+(rt->left+1)*lChannels+1]=g;
            pBuf[i*nPitch+(rt->left+1)*lChannels+2]=r;
            
            pBuf[i*nPitch+(rt->right-2)*lChannels]=b;
            pBuf[i*nPitch+(rt->right-2)*lChannels+1]=g;
            pBuf[i*nPitch+(rt->right-2)*lChannels+2]=r;
        }
    }
}
/*
#include "ft2build.h"
#include FT_FREETYPE_H
#import <opencv2/opencv.hpp>
int        m_fontType;
CvScalar   m_fontSize;
bool       m_fontUnderline;
float      m_fontDiaphaneity;
FT_Library m_library;   // ◊÷ø‚
FT_Face    m_face;      // ◊÷ÃÂ
void restoreFont()
{
    m_fontType = 0;            // 字体类型(不支持)
    
    m_fontSize.val[0] = 20;      // 字体大小
    m_fontSize.val[1] = 0.5;   // 空白字符大小比例
    m_fontSize.val[2] = 0.1;   // 间隔大小比例
    m_fontSize.val[3] = 0;      // 旋转角度(不支持)
    
    m_fontUnderline   = false;   // 下画线(不支持)
    
    m_fontDiaphaneity = 1.0;   // 色彩比例(可产生透明效果)
    
    // 设置字符大小
    
    FT_Set_Pixel_Sizes(m_face, (int)m_fontSize.val[0], 0);
}
void setFont(int *type, CvScalar *size, bool *underline, float *diaphaneity)
{
    // ≤Œ ˝∫œ∑®–‘ºÏ≤È
    
    if(type)
    {
        if(type >= 0) m_fontType = *type;
    }
    if(size)
    {
        m_fontSize.val[0] = fabs(size->val[0]);
        m_fontSize.val[1] = fabs(size->val[1]);
        m_fontSize.val[2] = fabs(size->val[2]);
        m_fontSize.val[3] = fabs(size->val[3]);
    }
    if(underline)
    {
        m_fontUnderline   = *underline;
    }
    if(diaphaneity)
    {
        m_fontDiaphaneity = *diaphaneity;
    }
    FT_Set_Pixel_Sizes(m_face, (int)m_fontSize.val[0], 0);
}



void putWChar(IplImage *img, wchar_t wc, CvPoint &pos, CvScalar color)
{
 
    FT_UInt glyph_index = FT_Get_Char_Index(m_face, wc);
    FT_Load_Glyph(m_face, glyph_index, FT_LOAD_DEFAULT);
    FT_Render_Glyph(m_face->glyph, FT_RENDER_MODE_MONO);
    
    //
    
    FT_GlyphSlot slot = m_face->glyph;
    
    // ––¡– ˝
    
    int rows = slot->bitmap.rows;
    int cols = slot->bitmap.width;
    
    //
    
    for(int i = 0; i < rows; ++i)
    {
        for(int j = 0; j < cols; ++j)
        {
            int off  = ((img->origin==0)? i: (rows-1-i))
            * slot->bitmap.pitch + j/8;
            
            if(slot->bitmap.buffer[off] & (0xC0 >> (j%8)))
            {
                int r = (img->origin==0)? pos.y - (rows-1-i): pos.y + i;;
                int c = pos.x + j;
                
                if(r >= 0 && r < img->height
                   && c >= 0 && c < img->width)
                {
                    CvScalar scalar = cvGet2D(img, r, c);
                    
                    // Ω¯––…´≤ »⁄∫œ
                    
                    float p = m_fontDiaphaneity;
                    for(int k = 0; k < 4; ++k)
                    {
                        scalar.val[k] = scalar.val[k]*(1-p) + color.val[k]*p;
                    }
                    
                    cvSet2D(img, r, c, scalar);
                }
            }
        } // end for
    } // end for
    
    // –ﬁ∏ƒœ¬“ª∏ˆ◊÷µƒ ‰≥ˆŒª÷√
    
    double space = m_fontSize.val[0]*m_fontSize.val[1];
    double sep   = m_fontSize.val[0]*m_fontSize.val[2];  
    
    pos.x += (int)((cols? cols: space) + sep);
}


int putText(IplImage *img, wchar_t    *text, CvPoint pos, CvScalar color)
{
    if(img == NULL) return -1;
    if(text == NULL) return -1;
    
    //
    int i;
 
    for(i=0;text[i]!='\0';++i)
    {
        putWChar(img, text[i], pos, color);
    }
    return i;
}
void DrawText(unsigned char* pBGR, int width, int height, int pitch,wchar_t* text, char* freetype, MPOINT pt, int r, int g, int b,int fontSize)
{
    IplImage* img = cvCreateImage(cvSize(width,height), 8, 3);
    memcpy(img->imageData,pBGR,img->widthStep*img->height);
    FT_Init_FreeType(&m_library);
    FT_Error res = FT_New_Face(m_library, freetype, 0, &m_face);//非0即错误
    restoreFont();

    float p = 1;
    CvScalar Scalar;
    Scalar.val[0] = fontSize;
    Scalar.val[1] = 0.5;
    Scalar.val[2] = 0.1;
    setFont(NULL, &Scalar, NULL, &p);
    CvPoint pt1;
    pt1.x = pt.x;
    pt1.y = pt.y;
 //   char freetype[MAX_PATH];
 //   strcpy(freetype,"/Users/qatech/Desktop/FRDemo/microsoft.ttf");

    
    setlocale(LC_ALL,"");
    putText(img, text, pt1, CV_RGB(r,g,b));

    memcpy(pBGR,img->imageData,img->widthStep*img->height);

    FT_Done_Face(m_face);
    FT_Done_FreeType(m_library);
    cvReleaseImage(&img);
}*/
void BGRCopyToBGRA(unsigned char* pBGR, int cutWidth, int cutHeight, unsigned char* pBGRA, int width, int height, int pitch)
{
    int cutPitch = cutWidth*3;
    for(int i=0;i<cutHeight-1;i++)//拷贝到左下角
    {
        for(int j=0;j<cutWidth;j++)
        {
            pBGRA[(i+height-cutHeight+1)*pitch+j*4] = pBGR[i*cutPitch+j*3];
            pBGRA[(i+height-cutHeight+1)*pitch+j*4+1] = pBGR[i*cutPitch+j*3+1];
            pBGRA[(i+height-cutHeight+1)*pitch+j*4+2] = pBGR[i*cutPitch+j*3+2];
        }
    }
}
void BGRAToRGBA(unsigned char* pBGRA, int width, int height, int pitch,unsigned char* pRGBA)
{
    int iSrcXStride = pitch;//LINE_BYTES(width, 32);
    int iSrcXStride2 = pitch;//LINE_BYTES(width, 32);
    int i, j;
    for(i = 0; i < height; i++)
    {
        for(j = 0; j < width; j++)
        {
            pRGBA[i*iSrcXStride+j*4  ]=pBGRA[i*iSrcXStride2+j*4+2];
            pRGBA[i*iSrcXStride+j*4+1]=pBGRA[i*iSrcXStride2+j*4+1];
            pRGBA[i*iSrcXStride+j*4+2] = pBGRA[i*iSrcXStride2+j*4];
            pRGBA[i*iSrcXStride+j*4+3] = pBGRA[i*iSrcXStride2+j*4+3];
        }
    }
}
/*
void Rotate_bgr(unsigned char* pSrcBGR, int width, int height, unsigned char* pDstBGR, int angle)
{
    IplImage* srcImg = cvCreateImage(cvSize(width,height), 8, 3);
    IplImage* dstImg = cvCreateImage(cvSize(height,width), 8, 3);
    
    memcpy(srcImg->imageData,pSrcBGR,srcImg->widthStep*srcImg->height);
    switch (angle) {
        case 90:
            cvTranspose(srcImg, dstImg);//此函数可顺时针旋转90度并左右flip
            break;
        case 270:
            cvTranspose(srcImg, dstImg);
            cvFlip(dstImg,NULL,0);//竖直翻转
            break;
        default:
            break;
    }
    memcpy(pDstBGR,dstImg->imageData,dstImg->widthStep*dstImg->height);
    cvReleaseImage(&srcImg);
    cvReleaseImage(&dstImg);
}
void cutImage(unsigned char* pSrcBGRA,int width,int height,unsigned char* pCutBGRA, int cutWidth,int cutHeight)
{
    IplImage* image = cvCreateImage(cvSize(width,height), 8, 3);
    memcpy(image->imageData,pSrcBGRA,image->widthStep*image->height);
    cvSetImageROI(image, cvRect(0,0,cutWidth,cutHeight));
    IplImage* cutImage = cvCreateImage(cvSize(cutWidth,cutHeight), 8, 3);
    cvCopy(image,cutImage,0);
    memcpy(pCutBGRA,cutImage->imageData,cutWidth*3*cutHeight);
    cvResetImageROI(image);
    cvReleaseImage(&image);
    cvReleaseImage(&cutImage);
}
void Flip_vertical_bgra(unsigned char* pSrcBGRA, int width, int height, int pitch, unsigned char* pDstBGRA)
{
    int i, j;
    
    if (pSrcBGRA == NULL)
    {
        return;
    }
    for (j = 0; j < height; j ++)
    {
        for (i = 0; i < width; i ++)
        {
            pDstBGRA[j*pitch+i*4] = pSrcBGRA[(height-j)*pitch+i*4];
            pDstBGRA[j*pitch+i*4+1] = pSrcBGRA[(height-j)*pitch+i*4+1];
            pDstBGRA[j*pitch+i*4+2] = pSrcBGRA[(height-j)*pitch+i*4+2];
            pDstBGRA[j*pitch+i*4+3] = pSrcBGRA[(height-j)*pitch+i*4+3];
        }
    }
}
void Flip_horizontal_bgra(unsigned char* pSrcBGRA, int width, int height, int pitch, unsigned char* pDstBGRA)
{
    int i, j;
    if (pSrcBGRA == NULL)
    {
        return;
    }
    for (j = 0; j < height; j += 1)
    {
        for (i = 1; i < width; i += 1)
        {
 
 //pDstBGRA[(j+1)*pitch-i*4] = pSrcBGRA[j*pitch+i*4];
 //pDstBGRA[(j+1)*pitch-i*4+1] = pSrcBGRA[j*pitch+i*4+1];
 //pDstBGRA[(j+1)*pitch-i*4+2] = pSrcBGRA[j*pitch+i*4+2];
 //pDstBGRA[(j+1)*pitch-i*4+3] = pSrcBGRA[j*pitch+i*4+3];
 
 
            pDstBGRA[j*pitch+(width-i)*4] = pSrcBGRA[j*pitch+i*4];
            pDstBGRA[j*pitch+(width-i)*4+1] = pSrcBGRA[j*pitch+i*4+1];
            pDstBGRA[j*pitch+(width-i)*4+2] = pSrcBGRA[j*pitch+i*4+2];
            pDstBGRA[j*pitch+(width-i)*4+3] = pSrcBGRA[j*pitch+i*4+3];
        }
    }
}
/*
void Flip_bgra(unsigned char* pSrcBGRA, int width, int height, unsigned char* pDstBGRA)
{
    IplImage* srcImg = cvCreateImage(cvSize(width,height), 8, 4);
    IplImage* dstImg = cvCreateImage(cvSize(width,height), 8, 4);

    memcpy(srcImg->imageData,pSrcBGRA,srcImg->widthStep*srcImg->height);
    cvFlip(srcImg,dstImg,1);//水平翻转
    memcpy(pDstBGRA,dstImg->imageData,dstImg->widthStep*dstImg->height);

    cvReleaseImage(&srcImg);
    cvReleaseImage(&dstImg);
}*/
@implementation common_utilitys
+ (UIImage *) imageWithBits: (unsigned char *) bits withSize: (CGSize) size
{
	// Create a color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	if (colorSpace == NULL)
    {
        fprintf(stderr, "Error allocating color space\n");
		free(bits);
        return nil;
    }
	
    CGContextRef context = CGBitmapContextCreate (bits, size.width, size.height, 8, size.width * 4, colorSpace, kCGImageAlphaPremultipliedLast);
    if (context == NULL)
    {
        fprintf (stderr, "Error: Context not created!");
        free (bits);
		CGColorSpaceRelease(colorSpace );
		return nil;
    }
	
    CGColorSpaceRelease(colorSpace );
	CGImageRef ref = CGBitmapContextCreateImage(context);
	free(CGBitmapContextGetData(context));
	CGContextRelease(context);
	
	UIImage *img = [UIImage imageWithCGImage:ref];
    //-lf
    //    UIImage *img = [UIImage imageWithCGImage:ref scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
	CFRelease(ref);
	return img;
}

+ (unsigned char *) bitmapFromImage: (UIImage *) image: (int) orient
{
    CGContextRef context;
    CGSize size;
    if(orient==1)//旋转90度
    {
        size.width = image.size.height;
        size.height = image.size.width;
        context = CreateARGBBitmapContext(size);
    }
	else
        context = CreateARGBBitmapContext(image.size);
    if (context == NULL) return NULL;
    CGRect rect;
    if(orient == 1)
        rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
    else
        rect = CGRectMake(0.0f, 0.0f, image.size.width, image.size.height);
    CGContextDrawImage(context, rect, image.CGImage);
	unsigned char *data = (unsigned char *)CGBitmapContextGetData (context);
	CGContextRelease(context);
	return data;
}
/*
 void Rotate_bgra(unsigned char* pSrcBGRA, int width, int height, int pitch, unsigned char* pDstBGRA, int lDegree)
 {
 int i=0,j=0;
 int srcPitch = //LINE_BYTES(width, 32);
 int dstPitch = //LINE_BYTES(height, 32);
 switch(lDegree)
 {
 case 90:
 for(i=0;i<width;i++)
 {
 for(j=0;j<height;j++)
 {
 pDstBGRA[i*dstPitch+4*j] = pSrcBGRA[(height-j)*srcPitch+4*i];
 pDstBGRA[i*dstPitch+4*j+1] = pSrcBGRA[(height-j)*srcPitch+4*i+1];
 pDstBGRA[i*dstPitch+4*j+2] = pSrcBGRA[(height-j)*srcPitch+4*i+2];
 pDstBGRA[i*dstPitch+4*j+3] = pSrcBGRA[(height-j)*srcPitch+4*i+3];
 }
 }
 break;
 case 270:
 break;
 default:
 break;
 }
 }*/


@end
