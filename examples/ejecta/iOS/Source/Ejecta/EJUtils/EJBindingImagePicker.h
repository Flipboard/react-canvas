#import "EJBindingBase.h"

#define EJ_PICKER_TYPE_FULLSCREEN 1
#define EJ_PICKER_TYPE_POPUP      2

typedef enum {
	kEJImagePickerTypeFullscreen,
	kEJImagePickerTypePopup
} EJImagePickerType;

@interface EJBindingImagePicker : EJBindingBase <UIImagePickerControllerDelegate, UIPopoverControllerDelegate, UINavigationControllerDelegate> {
	JSObjectRef callback;
	UIImagePickerController *picker;
	UIPopoverController *popover;
	NSString *imgFormat;
	float jpgCompression;
	EJImagePickerType pickerType;
	float maxJsWidth, maxJsHeight;
	float maxTexWidth, maxTexHeight;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info;
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker;
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popup;
- (void)successCallback:(JSValueRef[])params;
- (void)errorCallback:(NSString *)message;
- (void)closePicker:(JSContextRef)ctx;
- (UIImage *)reduceImageSize:(UIImage *)image;

+ (BOOL)isSourceTypeAvailable:(NSString *) sourceType;

@end
