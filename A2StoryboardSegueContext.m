//
//  A2StoryboardSegueContext.m
//
//  Created by Alexsander Akers on 10/31/11.
//  Copyright (c) 2011 Pandamonia LLC. All rights reserved.
//

#import <pthread.h>
#import "A2StoryboardSegueContext.h"

static id aContext;
static pthread_mutex_t mtx = PTHREAD_MUTEX_INITIALIZER;
static void *kContextKey;

@interface UIStoryboardSegue ()

- (id) a2_initWithIdentifier: (NSString *) identifier source: (UIViewController *) source destination: (UIViewController *) destination __attribute__((objc_method_family(init)));

@end

@implementation UIStoryboardSegue (A2StoryboardSegueContext)

- (id) a2_initWithIdentifier: (NSString *) identifier source: (UIViewController *) source destination: (UIViewController *) destination
{
	if ((self = [self a2_initWithIdentifier: identifier source: source destination: destination]))
	{
		if (aContext)
		{
			objc_setAssociatedObject(self, &kContextKey, aContext, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
			aContext = nil;
			
			// Unlock now
			pthread_mutex_unlock(&mtx);
		}
	}
	
	return self;
}
- (id) context
{
	return objc_getAssociatedObject(self, &kContextKey);
}

+ (void) load
{
	SEL orig = @selector(initWithIdentifier:source:destination:);
	SEL new = @selector(a2_initWithIdentifier:source:destination:);
	
	Method origMethod = class_getInstanceMethod(self, orig);
	Method newMethod = class_getInstanceMethod(self, new);
	
	if (class_addMethod(self, orig, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)))
		class_replaceMethod(self, new, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
	else
		method_exchangeImplementations(origMethod, newMethod);
}

@end

@implementation UIViewController (A2StoryboardSegueContext)

- (void) performSegueWithIdentifier: (NSString *) identifier sender: (id) sender context: (id) context
{
	// Lock the until we unlock above.
	pthread_mutex_lock(&mtx);
	aContext = context;
	
	[self performSegueWithIdentifier: identifier sender: sender];
}

@end
