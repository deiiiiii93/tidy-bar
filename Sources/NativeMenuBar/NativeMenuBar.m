#import "NativeMenuBar.h"
#import <objc/message.h>
#import <objc/runtime.h>
#import <dlfcn.h>

static NSError *TBError(NSString *message) {
    return [NSError errorWithDomain:@"com.tidybar.visibility" code:1
                          userInfo:@{NSLocalizedDescriptionKey: message}];
}

static BOOL TBMethodMatches(Class cls, SEL selector, unsigned int arguments,
                            const char *returnType, BOOL blockArgument) {
    Method method = class_getInstanceMethod(cls, selector);
    if (!method || method_getNumberOfArguments(method) != arguments) return NO;
    NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:method_getTypeEncoding(method)];
    if (strcmp(signature.methodReturnType, returnType)) return NO;
    for (NSUInteger index = 2; index < arguments; index++) {
        const char *type = [signature getArgumentTypeAtIndex:index];
        if (strcmp(type, blockArgument && index == arguments - 1 ? "@?" : "@")) return NO;
    }
    return YES;
}

@implementation TBMenuBarSession {
    id _assertion;
    BOOL _cancelled;
    BOOL _started;
}

+ (NSString *)unavailableReason {
    if (NSProcessInfo.processInfo.operatingSystemVersion.majorVersion < 27)
        return @"Native hiding requires macOS 27 or later.";
    if (!dlopen("/System/Library/PrivateFrameworks/MenuBarClientCore.framework/MenuBarClientCore", RTLD_NOW | RTLD_LOCAL))
        return @"This macOS build does not provide native menu bar hiding.";
    Class config = NSClassFromString(@"MBAssessmentModeConfiguration");
    Class assertion = NSClassFromString(@"MBAssessmentModeAssertion");
    if (!config || !assertion ||
        !TBMethodMatches(config, NSSelectorFromString(@"initWithAllowedSystemItems:allowedBundleIdentifiers:"), 4, "@", NO) ||
        !TBMethodMatches(assertion, NSSelectorFromString(@"activateWithConfiguration:completionHandler:"), 4, "v", YES) ||
        !TBMethodMatches(assertion, NSSelectorFromString(@"invalidate"), 2, "v", NO))
        return @"Apple changed the native hiding interface. Please leave icons expanded.";
    return nil;
}

- (void)activateAllowingBundles:(NSArray<NSString *> *)bundles
                    completion:(void (^)(NSError *))completion {
    NSAssert(NSThread.isMainThread, @"Visibility must be changed on the main thread");
    NSString *reason = [TBMenuBarSession unavailableReason];
    if (reason || _cancelled || _started) {
        completion(TBError(reason ?: @"This visibility request was cancelled or already started."));
        return;
    }
    _started = YES;
    @try {
        // MBSystemItemIdentifier.allCases was enumerated from the installed
        // macOS 27.0 framework: raw values 0...8, not bit flags. Keep all nine.
        // See docs/research/system-item-probe.swift and its recorded output.
        // Signature checks alone cannot qualify system behavior on OS updates.
        NSArray<NSNumber *> *systemItems = @[@0, @1, @2, @3, @4, @5, @6, @7, @8];
        Class configClass = NSClassFromString(@"MBAssessmentModeConfiguration");
        id config = ((id (*)(id, SEL, id, id))objc_msgSend)(
            [configClass alloc], NSSelectorFromString(@"initWithAllowedSystemItems:allowedBundleIdentifiers:"),
            systemItems, [bundles copy]);
        _assertion = [[NSClassFromString(@"MBAssessmentModeAssertion") alloc] init];
        if (!config || !_assertion) {
            completion(TBError(@"macOS could not create a visibility request."));
            return;
        }
        __weak TBMenuBarSession *weakSelf = self;
        ((void (*)(id, SEL, id, void (^)(NSError *)))objc_msgSend)(
            _assertion, NSSelectorFromString(@"activateWithConfiguration:completionHandler:"), config,
            ^(NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    TBMenuBarSession *session = weakSelf;
                    if (!session || session->_cancelled) {
                        completion(TBError(@"Visibility request cancelled."));
                    } else {
                        completion(error);
                    }
                });
            });
    } @catch (NSException *exception) {
        completion(TBError([NSString stringWithFormat:@"Native hiding failed: %@", exception.reason]));
    }
}

- (NSError *)releaseRestriction {
    NSAssert(NSThread.isMainThread, @"Visibility must be restored on the main thread");
    _cancelled = YES;
    @try {
        if (_assertion) {
            ((void (*)(id, SEL))objc_msgSend)(_assertion, NSSelectorFromString(@"invalidate"));
            _assertion = nil;
        }
        return nil;
    } @catch (NSException *exception) {
        // Keep the token so a subsequent restore can retry it.
        return TBError([NSString stringWithFormat:@"Could not restore the bar: %@. Quit Tidy Bar to release its connection.", exception.reason]);
    }
}

- (void)dealloc {
    @try {
        if (_assertion) ((void (*)(id, SEL))objc_msgSend)(_assertion, NSSelectorFromString(@"invalidate"));
    } @catch (NSException *exception) {
        NSLog(@"Tidy Bar: cleanup failed: %@", exception.reason);
    }
}
@end
