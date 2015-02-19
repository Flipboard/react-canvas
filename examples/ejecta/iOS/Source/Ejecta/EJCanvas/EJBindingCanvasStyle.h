#import "EJBindingBase.h"

@class EJBindingCanvas;
@interface EJBindingCanvasStyle : EJBindingBase {
	EJBindingCanvas *binding;
}

@property (assign, nonatomic) EJBindingCanvas *binding;
@property (readonly, nonatomic) JSObjectRef jsObject;
@end
