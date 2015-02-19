
#import "EJBindingKeyInput.h"
#import "EJJavaScriptView.h"

@implementation EJKeyInputResponder

- (UIResponder*)nextResponder{
    return [self.delegate nextResponderForKeyInput:self];
}

- (BOOL)becomeFirstResponder{
    BOOL isCurrent = [self isFirstResponder];
    BOOL become = [super becomeFirstResponder];
    if (become && !isCurrent && [self.delegate respondsToSelector:@selector(keyInputDidBecomeFirstResponder:)]) {
        [self.delegate keyInputDidBecomeFirstResponder:self];
    }
    return become;
}

- (BOOL)canBecomeFirstResponder{
    return YES;
}

- (BOOL)resignFirstResponder{
    BOOL isCurrent = [self isFirstResponder];
    BOOL resign = [super resignFirstResponder];
    if (resign && isCurrent && [self.delegate respondsToSelector:@selector(keyInputDidResignFirstResponderStatus:)]) {
        [self.delegate keyInputDidResignFirstResponderStatus:self];
    }
    return resign;
}

- (void)deleteBackward{
    if (self.delegate && [self.delegate respondsToSelector:@selector(keyInputDidDeleteBackwards:)]) {
        [self.delegate keyInputDidDeleteBackwards:self];
    }
}

- (void)insertText:(NSString *)text{
    if ([self.delegate respondsToSelector:@selector(keyInput:insertText:)]) {
        [self.delegate keyInput:self insertText:text];
    }
}

- (BOOL)hasText{
    return YES;
}

@end

@interface EJBindingKeyInput ()
@property (nonatomic, retain) EJKeyInputResponder *inputController;
@property (nonatomic, retain) NSMutableString *value;
@end

@implementation EJBindingKeyInput

- (void)createWithJSObject:(JSObjectRef)obj scriptView:(EJJavaScriptView *)view {
	[super createWithJSObject:obj scriptView:view];
    self.inputController = [[[EJKeyInputResponder alloc] init] autorelease];
    self.inputController.delegate = self;
    self.value = [NSMutableString string];
}

- (void)dealloc
{
    self.inputController.delegate = nil;
    [_inputController release];
    [_value release];
    [super dealloc];
}

EJ_BIND_FUNCTION(focus, ctx, argc, argv){
    return JSValueMakeBoolean(ctx, [self.inputController becomeFirstResponder]);
}

EJ_BIND_FUNCTION(blur, ctx, argc, argv){
    return JSValueMakeBoolean(ctx, [self.inputController resignFirstResponder]);
}

EJ_BIND_FUNCTION(isOpen, ctx, argc, argv){
    return JSValueMakeBoolean(ctx, [self.inputController isFirstResponder]);
}

EJ_BIND_GET(value, ctx){
    return NSStringToJSValue(ctx, self.value);
}

EJ_BIND_SET(value, ctx, value){
    [self.value setString:JSValueToNSString(ctx, value)];
}

EJ_BIND_EVENT(focus);
EJ_BIND_EVENT(blur);
EJ_BIND_EVENT(delete);
EJ_BIND_EVENT(change);

#pragma mark -
#pragma mark EJKeyInput delegate

- (UIResponder*)nextResponderForKeyInput:(EJKeyInputResponder *)keyInput{
    return scriptView;
}

- (void)keyInput:(EJKeyInputResponder *)keyInput insertText:(NSString *)text
{
    [self.value appendString:text];

    [self triggerEvent:@"keypress" properties:(JSEventProperty[]){
		{"char", NSStringToJSValue(scriptView.jsGlobalContext, text)},
		{NULL, NULL}
	}];
    
    [self triggerEvent:@"change"];
}

- (void)keyInputDidDeleteBackwards:(EJKeyInputResponder *)keyInput{
    [self triggerEvent:@"delete"];
}

- (void)keyInputDidResignFirstResponderStatus:(EJKeyInputResponder *)keyInput{
    [self triggerEvent:@"blur"];
}

- (void)keyInputDidBecomeFirstResponder:(EJKeyInputResponder *)keyInput{
    [self triggerEvent:@"focus"];
}

@end
