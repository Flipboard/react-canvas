#import <Foundation/Foundation.h>
#import "EJTexture.h"
#import "EJImageData.h"
#import "EJPath.h"
#import "EJCanvas2DTypes.h"
#import "EJCanvasContext.h"
#import "EJFont.h"
#import "EJFontCache.h"
#import "EJSharedOpenGLContext.h"

#define EJ_CANVAS_STATE_STACK_SIZE 16

typedef enum {
	kEJLineCapButt,
	kEJLineCapRound,
	kEJLineCapSquare
} EJLineCap;

typedef enum {
	kEJLineJoinMiter,
	kEJLineJoinBevel,
	kEJLineJoinRound
} EJLineJoin;

typedef enum {
	kEJTextBaselineAlphabetic,
	kEJTextBaselineMiddle,
	kEJTextBaselineTop,
	kEJTextBaselineHanging,
	kEJTextBaselineBottom,
	kEJTextBaselineIdeographic
} EJTextBaseline;

typedef enum {
	kEJTextAlignStart,
	kEJTextAlignEnd,
	kEJTextAlignLeft,
	kEJTextAlignCenter,
	kEJTextAlignRight
} EJTextAlign;

typedef enum {
	kEJCompositeOperationSourceOver,
	kEJCompositeOperationLighter,
	kEJCompositeOperationDarker,
	kEJCompositeOperationDestinationOut,
	kEJCompositeOperationDestinationOver,
	kEJCompositeOperationSourceAtop,
	kEJCompositeOperationXOR,
	kEJCompositeOperationCopy,
	kEJCompositeOperationSourceIn,
	kEJCompositeOperationDestinationIn,
	kEJCompositeOperationSourceOut,
	kEJCompositeOperationDestinationAtop
} EJCompositeOperation;

typedef struct { GLenum source; GLenum destination; float alphaFactor; } EJCompositeOperationFunc;
extern const EJCompositeOperationFunc EJCompositeOperationFuncs[];

@class EJCanvasPattern;
@class EJCanvasGradient;

@protocol EJFillable
@end

typedef struct {
	CGAffineTransform transform;
	
	EJCompositeOperation globalCompositeOperation;
	EJColorRGBA fillColor;
	NSObject<EJFillable> *fillObject;
	EJColorRGBA strokeColor;
	NSObject<EJFillable> *strokeObject;
	float globalAlpha;
	
	float lineWidth;
	EJLineCap lineCap;
	EJLineJoin lineJoin;
	float miterLimit;
	
	EJTextAlign textAlign;
	EJTextBaseline textBaseline;
	EJFontDescriptor *font;
	
	EJPath *clipPath;	
} EJCanvasState;

static inline EJColorRGBA EJCanvasBlendColor( EJCanvasState *state, EJColorRGBA color ) {
	float alpha = state->globalAlpha * (float)color.rgba.a/255.0f;
	return (EJColorRGBA){ .rgba = {
		.r = (float)color.rgba.r * alpha,
		.g = (float)color.rgba.g * alpha,
		.b = (float)color.rgba.b * alpha,
		.a = EJCompositeOperationFuncs[state->globalCompositeOperation].alphaFactor *
			 (float)color.rgba.a * state->globalAlpha
	}};
}

static inline EJColorRGBA EJCanvasBlendWhiteColor( EJCanvasState *state ) {
	return EJCanvasBlendColor(state, (EJColorRGBA){.hex = 0xffffffff});
}

static inline EJColorRGBA EJCanvasBlendFillColor( EJCanvasState *state ) {
	return EJCanvasBlendColor(state, state->fillColor);
}

static inline EJColorRGBA EJCanvasBlendStrokeColor( EJCanvasState *state ) {
	return EJCanvasBlendColor(state, state->strokeColor);
}



@class EJJavaScriptView;
@interface EJCanvasContext2D : EJCanvasContext {
	GLuint viewFrameBuffer, viewRenderBuffer;
	GLuint msaaFrameBuffer, msaaRenderBuffer;
	GLuint stencilBuffer;
	GLubyte stencilMask;
	
	short bufferWidth, bufferHeight;
	
	GLenum textureFilter;
	EJTexture *currentTexture;
	EJPath *path;
	
	EJVertex *vertexBuffer;
	int vertexBufferSize;
	int vertexBufferIndex;
	
	int stateIndex;
	EJCanvasState stateStack[EJ_CANVAS_STATE_STACK_SIZE];
	EJCanvasState *state;
	
	BOOL upsideDown;
	
	EJFontCache *fontCache;
	
	EJJavaScriptView *scriptView;
	EJGLProgram2D *currentProgram;
	EJSharedOpenGLContext *sharedGLContext;
}

- (id)initWithScriptView:(EJJavaScriptView *)scriptViewp width:(short)widthp height:(short)heightp;
- (void)create;
- (void)resizeToWidth:(short)newWidth height:(short)newHeight;
- (void)resetFramebuffer;
- (void)createStencilBufferOnce;
- (void)bindVertexBuffer;
- (void)prepare;
- (void)setTexture:(EJTexture *)newTexture;
- (void)setProgram:(EJGLProgram2D *)program;
- (void)pushTriX1:(float)x1 y1:(float)y1 x2:(float)x2 y2:(float)y2
	x3:(float)x3 y3:(float)y3
	color:(EJColorRGBA)color
	withTransform:(CGAffineTransform)transform;
- (void)pushQuadV1:(EJVector2)v1 v2:(EJVector2)v2 v3:(EJVector2)v3 v4:(EJVector2)v4
	color:(EJColorRGBA)color
	withTransform:(CGAffineTransform)transform;
- (void)pushRectX:(float)x y:(float)y w:(float)w h:(float)h
	color:(EJColorRGBA)color
	withTransform:(CGAffineTransform)transform;
- (void)pushFilledRectX:(float)x y:(float)y w:(float)w h:(float)h
	fillable:(NSObject<EJFillable> *)fillable
	color:(EJColorRGBA)color
	withTransform:(CGAffineTransform)transform;
- (void)pushGradientRectX:(float)x y:(float)y w:(float)w h:(float)h
	gradient:(EJCanvasGradient *)gradient
	color:(EJColorRGBA)color
	withTransform:(CGAffineTransform)transform;
- (void)pushPatternedRectX:(float)x y:(float)y w:(float)w h:(float)h
	pattern:(EJCanvasPattern *)pattern
	color:(EJColorRGBA)color
	withTransform:(CGAffineTransform)transform;
- (void)pushTexturedRectX:(float)x y:(float)y w:(float)w h:(float)h
	tx:(float)tx ty:(float)ty tw:(float)tw th:(float)th
	color:(EJColorRGBA)color
	withTransform:(CGAffineTransform)transform;
- (void)flushBuffers;

- (void)save;
- (void)restore;
- (void)rotate:(float)angle;
- (void)translateX:(float)x y:(float)y;
- (void)scaleX:(float)x y:(float)y;
- (void)transformM11:(float)m11 m12:(float)m12 m21:(float)m21 m22:(float)m2 dx:(float)dx dy:(float)dy;
- (void)setTransformM11:(float)m11 m12:(float)m12 m21:(float)m21 m22:(float)m2 dx:(float)dx dy:(float)dy;
- (void)drawImage:(EJTexture *)image sx:(float)sx sy:(float)sy sw:(float)sw sh:(float)sh dx:(float)dx dy:(float)dy dw:(float)dw dh:(float)dh;
- (void)fillRectX:(float)x y:(float)y w:(float)w h:(float)h;
- (void)strokeRectX:(float)x y:(float)y w:(float)w h:(float)h;
- (void)clearRectX:(float)x y:(float)y w:(float)w h:(float)h;
- (EJImageData*)getImageDataScaled:(float)scale flipped:(bool)flipped sx:(short)sx sy:(short)sy sw:(short)sw sh:(short)sh;
- (EJImageData*)getImageDataSx:(short)sx sy:(short)sy sw:(short)sw sh:(short)sh;
- (EJImageData*)getImageDataHDSx:(short)sx sy:(short)sy sw:(short)sw sh:(short)sh;
- (void)putImageData:(EJImageData*)imageData dx:(float)dx dy:(float)dy;
- (void)putImageDataHD:(EJImageData*)imageData dx:(float)dx dy:(float)dy;
- (void)putImageData:(EJImageData*)imageData scaled:(float)scale dx:(float)dx dy:(float)dy;
- (void)beginPath;
- (void)closePath;
- (void)fill:(EJPathFillRule)fillRule;
- (void)stroke;
- (void)moveToX:(float)x y:(float)y;
- (void)lineToX:(float)x y:(float)y;
- (void)rectX:(float)x y:(float)y w:(float)w h:(float)h;
- (void)bezierCurveToCpx1:(float)cpx1 cpy1:(float)cpy1 cpx2:(float)cpx2 cpy2:(float)cpy2 x:(float)x y:(float)y;
- (void)quadraticCurveToCpx:(float)cpx cpy:(float)cpy x:(float)x y:(float)y;
- (void)arcToX1:(float)x1 y1:(float)y1 x2:(float)x2 y2:(float)y2 radius:(float)radius;
- (void)arcX:(float)x y:(float)y radius:(float)radius startAngle:(float)startAngle endAngle:(float)endAngle antiClockwise:(BOOL)antiClockwise;

- (void)fillText:(NSString *)text x:(float)x y:(float)y;
- (void)strokeText:(NSString *)text x:(float)x y:(float)y;
- (EJTextMetrics)measureText:(NSString *)text;

- (void)clip:(EJPathFillRule)fillRule;
- (void)resetClip;

@property (nonatomic) EJCanvasState *state;
@property (nonatomic) EJCompositeOperation globalCompositeOperation;
@property (nonatomic, retain) EJFontDescriptor *font;
@property (nonatomic, retain) NSObject<EJFillable> *fillObject;
@property (nonatomic, retain) NSObject<EJFillable> *strokeObject;
@property (nonatomic) BOOL imageSmoothingEnabled;
@property (nonatomic) GLubyte stencilMask;

/* TODO: not yet implemented:
	shadowOffsetX
	shadowOffsetY
	shadowBlur
	shadowColor
	isPointInPath(x, y)
*/
@end
