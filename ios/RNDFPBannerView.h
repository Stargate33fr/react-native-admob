#import "RCTEventDispatcher.h"
@import GoogleMobileAds;

@class RCTEventDispatcher;

@interface RNDFPBannerView : UIView <GADBannerViewDelegate>

@property (nonatomic, copy) NSString *bannerSize;
@property (nonatomic, copy) NSString *adUnitID;
@property (nonatomic, copy) NSString *targeting;
@property (nonatomic, copy) NSString *fixedWidth;
@property (nonatomic, copy) NSString *fixedHeight;

- (instancetype)initWithEventDispatcher:(RCTEventDispatcher *)eventDispatcher NS_DESIGNATED_INITIALIZER;
- (GADAdSize)getAdSizeFromString:(NSString *)bannerSize;
- (void)loadBanner;

@end
