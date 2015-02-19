#import "EJBindingBase.h"
#import "EJImageData.h"
#import "EJDrawable.h"

@interface EJBindingImageData : EJBindingBase <EJDrawable> {
	EJImageData *imageData;
	JSObjectRef dataArray;
}

- (id)initWithImageData:(EJImageData *)data;

@property (readonly, nonatomic) EJImageData *imageData;
@property (readonly, nonatomic) EJTexture *texture;

@end
