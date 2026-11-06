#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// All calls, including completion, run on the main thread. This bridge never
/// starts a public assessment session or changes persistent system settings.
@interface TBMenuBarSession : NSObject
+ (nullable NSString *)unavailableReason;
- (void)activateAllowingBundles:(NSArray<NSString *> *)bundles
                    completion:(void (^)(NSError * _Nullable error))completion;
/// Nil means the restriction was released. An error requires quitting the app.
- (nullable NSError *)releaseRestriction;
@end

NS_ASSUME_NONNULL_END
