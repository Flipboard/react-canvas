#import <MobileCoreServices/UTCoreTypes.h> // for media filtering
#import "EJBindingImagePicker.h"
#import "EJJavaScriptView.h"
#import "EJTexture.h"
#import "EJBindingImage.h"

@implementation EJBindingImagePicker


// pick a picture
EJ_BIND_FUNCTION(getPicture, ctx, argc, argv) {
	if( argc < 1 ) { return NULL; }
	
	// retrieve the callback
	JSValueUnprotectSafe(ctx, callback);
	callback = JSValueToObject(ctx, argv[0], NULL);
	
	// retrieve the options if any
	NSDictionary *options = nil;
	if( argc > 1 && JSValueIsObject(ctx, argv[1]) ) {
		options = (NSDictionary *) JSValueToNSObject(ctx, argv[1]);
	}
	
	// retrieve maximum Open GL ES texture size
	GLint maxTextureSize;
	glGetIntegerv(GL_MAX_TEXTURE_SIZE, &maxTextureSize);
	float maxTexSize = (float)maxTextureSize;
	
	// set current options
	NSString *sourceType = options[@"sourceType"]     ? options[@"sourceType"]                  : @"PhotoLibrary";
	maxJsWidth           = options[@"maxWidth"]       ? [options[@"maxWidth"] floatValue]       : maxTexSize / [UIScreen mainScreen].scale;
	maxJsHeight          = options[@"maxHeight"]      ? [options[@"maxHeight"] floatValue]      : maxTexSize / [UIScreen mainScreen].scale;
	float popupX         = options[@"popupX"]         ? [options[@"popupX"] floatValue]         : 0.0f;
	float popupY         = options[@"popupY"]         ? [options[@"popupY"] floatValue]         : 0.0f;
	float popupWidth     = options[@"popupWidth"]     ? [options[@"popupWidth"] floatValue]     : 1.0f;
	float popupHeight    = options[@"popupHeight"]    ? [options[@"popupHeight"] floatValue]    : 1.0f;
	
	// Source type validation
	if( ![EJBindingImagePicker isSourceTypeAvailable:sourceType] ) {
		[self errorCallback:[NSString stringWithFormat:@"sourceType `%@` is not available on this device or the source collection is empty.", sourceType]];
		return NULL;
	}
	
	// js picture maximum width and height validation
	maxJsWidth = MIN(maxJsWidth, maxTexSize / [UIScreen mainScreen].scale);
	maxJsHeight = MIN(maxJsHeight, maxTexSize / [UIScreen mainScreen].scale);
	
	// gl texture maximum width and height
	maxTexWidth = maxJsWidth * [UIScreen mainScreen].scale;
	maxTexHeight = maxJsHeight * [UIScreen mainScreen].scale;
	
	// identify the type of picker we need: full screen or popup
	if(
		UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad &&
		![sourceType isEqualToString:@"Camera"]
	) {
		pickerType = kEJImagePickerTypePopup;
	}
	else {
		pickerType = kEJImagePickerTypeFullscreen;
	}
	
	// init and alloc
	picker = [[UIImagePickerController alloc] init];
	picker.delegate = self;
	if( pickerType == kEJImagePickerTypePopup ) {
		popover = [[UIPopoverController alloc] initWithContentViewController:picker];
		popover.delegate = self;
	}
	
	// limit to pictures only
	[picker setMediaTypes: @[(NSString *)kUTTypeImage]];
	
	// set the source type
	picker.sourceType = [EJBindingImagePicker getSourceTypeClass:sourceType];
	
	// we are ready to open the picker, let's retain the variables we need for the callback
	JSValueProtect(ctx, callback);
	
	// Protect this picker object from garbage collection, as the callback function
	// may be the only thing holding on to it
	JSValueProtect(scriptView.jsGlobalContext, jsObject);
	
	// open it
	if ( pickerType == kEJImagePickerTypePopup ) {
		[popover
			presentPopoverFromRect:CGRectMake(popupX, popupY, popupWidth, popupHeight)
			inView:scriptView.window.rootViewController.view
			permittedArrowDirections:UIPopoverArrowDirectionAny
			animated:YES];
	}
	else {
		[scriptView.window.rootViewController presentViewController:picker animated:YES completion:nil];
	}
	
    return NULL;
}


// to know if a source type (`PhotoLibrary`, `SavedPhotosAlbum` or `Camera`) is available on the device at the moment
EJ_BIND_FUNCTION(isSourceTypeAvailable, ctx, argc, argv) {
	if( argc < 1 ) { return NULL; }
	
	NSString *sourceType = JSValueToNSString(ctx, argv[0]);
	return JSValueMakeBoolean(ctx, [EJBindingImagePicker isSourceTypeAvailable:sourceType]);
}


// user picked a picture
- (void)imagePickerController:(UIImagePickerController *)_picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	// retrieve image data
	UIImage *rawImage = info[UIImagePickerControllerOriginalImage];
	UIImage *chosenImage;
	
	// resize it if required
	if( (rawImage.size.width * rawImage.scale) > maxTexWidth || (rawImage.size.height * rawImage.scale) > maxTexHeight ) {
		chosenImage = [self reduceImageSize:rawImage];
	}
	else {
		chosenImage = rawImage;
	}
	
	// retrieve the context
	JSContextRef ctx = scriptView.jsGlobalContext;
	
	// create a texture with the UIImage instance
	EJTexture *texture = [[EJTexture alloc] initWithUIImage:chosenImage];
	
	// create the EJBindingImage instance, attach the texture
	EJBindingImage *image = [[EJBindingImage alloc] initWithContext:ctx argc:0 argv:NULL];
	[image setTexture:texture path:[info[UIImagePickerControllerReferenceURL] absoluteString]];
	
	// create the javascript image object
	JSObjectRef jsImage = [EJBindingImage createJSObjectWithContext:ctx scriptView:scriptView instance:image];
	
	// call the callback
	JSValueRef params[] = { NULL, jsImage };
	[self successCallback:params];
	
	// cleaning
	[image release];
	[texture release];
	
	// close and release
	[self closePicker:ctx];
}


// user cancelled
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)_picker {
	// error
	[self errorCallback:@"User cancelled"];
	
	// close and release
	JSContextRef ctx = scriptView.jsGlobalContext;
	[self closePicker:ctx];
}


// popup was dismissed (relevant only when the picker was opened as a popup)
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popup {
	JSContextRef ctx = scriptView.jsGlobalContext;
	// close and release
	[self closePicker:ctx];
}


// success callback
- (void)successCallback:(JSValueRef[])params {
	[scriptView invokeCallback:callback thisObject:jsObject argc:2 argv:params];
}


// error callback
- (void)errorCallback:(NSString *)message {
	JSContextRef ctx = scriptView.jsGlobalContext;
	JSValueRef params[] = { NSStringToJSValue(ctx, message), NULL };
	[scriptView invokeCallback:callback thisObject:jsObject argc:1 argv:params];
}


// to close the picker and release retained stuff
- (void)closePicker:(JSContextRef)ctx {
	// close the picker
	[picker dismissViewControllerAnimated:YES completion:NULL];
	
	// close the popup
	if( pickerType == kEJImagePickerTypePopup ) {
		[popover dismissPopoverAnimated:TRUE];
	}
	
	// release all the retained stuff
	JSValueUnprotectSafe(ctx, callback);
	[picker release];
	NSLog(@"picker released");
	if ( pickerType == kEJImagePickerTypePopup ) {
		[popover release];
		NSLog(@"popup released");
	}
	JSValueUnprotect(scriptView.jsGlobalContext, jsObject);
}


// reduce an image to fit the maximum values
- (UIImage *)reduceImageSize:(UIImage *)image {
	float originalWidth = image.size.width;
	float originalHeight = image.size.height;
	float ratio = MIN(maxTexWidth / originalWidth, maxTexHeight / originalHeight);
	float targetWidth = lroundf(originalWidth * ratio);
	float targetHeight = lroundf(originalHeight * ratio);
	
	CGSize newSize = CGSizeMake(targetWidth, targetHeight);
	UIGraphicsBeginImageContextWithOptions(newSize, NO, 1.0);
	[image drawInRect:CGRectMake(0, 0, targetWidth, targetHeight)];
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return newImage;
}


// to check if a source type is available at the moment on the current device
+ (BOOL)isSourceTypeAvailable:(NSString *) sourceType {
	if( ![sourceType isEqualToString:@"PhotoLibrary"] && ![sourceType isEqualToString:@"SavedPhotosAlbum"] && ![sourceType isEqualToString:@"Camera"] ) {
		return NO;
	}
	UIImagePickerControllerSourceType sourceTypeClass = [self getSourceTypeClass:sourceType];
	if( ![UIImagePickerController isSourceTypeAvailable:sourceTypeClass] ) {
		return NO;
	}
	return YES;
}


// to retrieve the source type enum number from string source type
+ (UIImagePickerControllerSourceType)getSourceTypeClass:(NSString *) sourceType {
	if( [sourceType isEqualToString:@"PhotoLibrary"] ) {
		return UIImagePickerControllerSourceTypePhotoLibrary;
	} else if( [sourceType isEqualToString:@"SavedPhotosAlbum"] ) {
		return UIImagePickerControllerSourceTypeSavedPhotosAlbum;
	} else if( [sourceType isEqualToString:@"Camera"] ) {
		return UIImagePickerControllerSourceTypeCamera;
	}
	return UIImagePickerControllerSourceTypePhotoLibrary;
}

@end