#import "BJLocation.h"
#import "BJSBAlertItem.h"
#import "../BJSharedInfo.h"

@interface CLLocationManager (BlackJacketPrivate)
+ (void)setAuthorizationStatusByType:(CLAuthorizationStatus)type forBundleIdentifier:(NSString *)bundle;
@end

NSNotificationName const BJLocationDidChangeNotification = @"BJLocationDidChangeNotification";
NSString *const BJLocationNewLocationKey = @"BJLocationNewLocationKey";

@implementation BJLocation {
    /// LocationManager of which we are the delegate, need to hold a strong reference to this
    CLLocationManager *_locationManager;
}

+ (instancetype)sharedInstance {
    static dispatch_once_t dispatchOnce;
    static BJLocation *ret = nil;
    
    dispatch_once(&dispatchOnce, ^{
        ret = self.new;
    });
    
    return ret;
}

- (instancetype)init {
    if (self = [super init]) {
        force_shared_instace_runtime;
        
        _locationManager = CLLocationManager.new;
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        
        // bundleID should always be com.apple.springboard, but didn't really want to hard code it
        NSString *bundleID = NSBundle.mainBundle.bundleIdentifier;
        // authorizationStatus seems to be needed to be set twice
        while (CLLocationManager.authorizationStatus != kCLAuthorizationStatusAuthorizedAlways) {
            [CLLocationManager setAuthorizationStatusByType:kCLAuthorizationStatusAuthorizedAlways forBundleIdentifier:bundleID];
        }
        
        [_locationManager startUpdatingLocation];
    }
    
    return self;
}

- (void)forcePreciseLocationUpdate {
    [_locationManager requestLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    // Required at runtime, we don't have any error handling right now
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    _latestLocation = locations.lastObject;
    
    NSDictionary<NSString *, id> *notifInfo = @{ BJLocationNewLocationKey : _latestLocation };
    [NSNotificationCenter.defaultCenter postNotificationName:BJLocationDidChangeNotification object:self userInfo:notifInfo];
}

+ (void)load {
    NSNotificationCenter *notifCenter = NSNotificationCenter.defaultCenter;
    // Just for safety reasons, wait until SpringBoard has finished launchig to request location information
    [notifCenter addObserverForName:UIApplicationDidFinishLaunchingNotification object:NULL queue:NULL usingBlock:^(NSNotification *note) {
        [BJLocation sharedInstance];
    }];
}

@end
