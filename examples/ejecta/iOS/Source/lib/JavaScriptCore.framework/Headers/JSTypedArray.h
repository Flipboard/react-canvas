#ifndef JSTypedArray_h
#define JSTypedArray_h

#include <JavaScriptCore/JSValueRef.h>

#ifdef __cplusplus
extern "C" {
#endif

/*!
@enum JSType
@abstract     A constant identifying the Typed Array type of a JSValue.
@constant     kJSTypedArrayTypeNone                 Not a Typed Array.
@constant     kJSTypedArrayTypeInt8Array            Int8Array
@constant     kJSTypedArrayTypeInt16Array           Int16Array
@constant     kJSTypedArrayTypeInt32Array           Int32Array
@constant     kJSTypedArrayTypeUint8Array           Int8Array
@constant     kJSTypedArrayTypeUint8ClampedArray    Int8ClampedArray
@constant     kJSTypedArrayTypeUint16Array          Uint16Array
@constant     kJSTypedArrayTypeUint32Array          Uint32Array
@constant     kJSTypedArrayTypeFloat32Array         Float32Array
@constant     kJSTypedArrayTypeFloat64Array         Float64Array
@constant     kJSTypedArrayTypeArrayBuffer          ArrayBuffer
*/
typedef enum {
    kJSTypedArrayTypeNone,
    kJSTypedArrayTypeInt8Array,
    kJSTypedArrayTypeInt16Array,
    kJSTypedArrayTypeInt32Array,
    kJSTypedArrayTypeUint8Array,
    kJSTypedArrayTypeUint8ClampedArray,
    kJSTypedArrayTypeUint16Array,
    kJSTypedArrayTypeUint32Array,
    kJSTypedArrayTypeFloat32Array,
    kJSTypedArrayTypeFloat64Array,
    kJSTypedArrayTypeArrayBuffer
} JSTypedArrayType;

/*!
@function
@abstract           Returns a JavaScript value's Typed Array type
@param ctx          The execution context to use.
@param value        The JSValue whose Typed Array type you want to obtain.
@result             A value of type JSTypedArrayType that identifies value's Typed Array type.
*/
JS_EXPORT JSTypedArrayType JSTypedArrayGetType(JSContextRef ctx, JSValueRef value);

/*!
@function
@abstract           Creates a JavaScript Typed Array with the given number of elements
@param ctx          The execution context to use.
@param arrayType    A value of type JSTypedArrayType identifying the type of array you want to create
@param numElements  The number of elements for the array.
@result             A JSObjectRef that is a Typed Array or NULL if there was an error
*/
JS_EXPORT JSObjectRef JSTypedArrayMake(JSContextRef ctx, JSTypedArrayType arrayType, size_t numElements);

/*!
@function
@abstract           Returns a pointer to a Typed Array's data in memory
@param ctx          The execution context to use.
@param value        The JSValue whose Typed Array type data pointer you want to obtain.
@param byteLength   A pointer to a size_t in which to store the byte length of the Typed Array
@result             A pointer to the Typed Array's data or NULL if the JSValue is not a Typed Array
*/
JS_EXPORT void * JSTypedArrayGetDataPtr(JSContextRef ctx, JSValueRef value, size_t * byteLength);


#ifdef __cplusplus
}
#endif

#endif /* JSTypedArray_h */
