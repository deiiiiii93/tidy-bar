// Read-only capability probe. Does not instantiate a configuration/assertion,
// activate hiding, enumerate other applications, or request privacy permission.
// Build/run instructions are in 2026-11-06-native-visibility.md.
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <dlfcn.h>

int main(void) {
    @autoreleasepool {
        const char *path = "/System/Library/PrivateFrameworks/MenuBarClientCore.framework/MenuBarClientCore";
        void *handle = dlopen(path, RTLD_NOW | RTLD_LOCAL);
        NSMutableDictionary *result = [@{
            @"os": NSProcessInfo.processInfo.operatingSystemVersionString,
            @"frameworkLoaded": @(handle != NULL),
            @"activationAttempted": @NO,
            @"functionalHidingVerified": @NO
        } mutableCopy];
        if (!handle) {
            const char *error = dlerror();
            result[@"loadError"] = error ? @(error) : @"Unknown load error";
        }
        NSDictionary *requirements = @{
            @"MBAssessmentModeConfiguration": @[@"initWithAllowedSystemItems:allowedBundleIdentifiers:"],
            @"MBAssessmentModeAssertion": @[@"activateWithConfiguration:completionHandler:", @"invalidate"]
        };
        BOOL available = handle != NULL;
        NSMutableDictionary *classes = [NSMutableDictionary dictionary];
        for (NSString *name in requirements) {
            Class cls = handle ? NSClassFromString(name) : Nil;
            NSMutableDictionary *entry = [@{@"present": @(cls != Nil)} mutableCopy];
            available &= cls != Nil;
            for (NSString *selector in requirements[name]) {
                Method method = cls ? class_getInstanceMethod(cls, NSSelectorFromString(selector)) : NULL;
                entry[selector] = method ? @(method_getTypeEncoding(method)) : @"MISSING";
                available &= method != NULL;
            }
            classes[name] = entry;
        }
        result[@"classes"] = classes;
        result[@"requiredSymbolsPresent"] = @(available);
        NSData *json = [NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted | NSJSONWritingSortedKeys error:nil];
        puts([[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding].UTF8String);
        // Keep the system framework loaded until process exit.
        return available ? 0 : 1;
    }
}
