#import <Foundation/Foundation.h>

@protocol EJPresentable

- (void)present;
- (void)finish;

@property (nonatomic) CGRect style;

@end
