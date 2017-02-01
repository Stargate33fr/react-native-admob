#import "RNDFPBannerView.h"
#import "RCTBridgeModule.h"
#import "UIView+React.h"
#import "RCTLog.h"

@implementation RNDFPBannerView {
    DFPBannerView  *_bannerView;
    RCTEventDispatcher *_eventDispatcher;
}

- (instancetype)initWithEventDispatcher:(RCTEventDispatcher *)eventDispatcher
{
    if ((self = [super initWithFrame:CGRectZero])) {
        _eventDispatcher = eventDispatcher;
    }
    return self;
}

RCT_NOT_IMPLEMENTED(- (instancetype)initWithFrame:(CGRect)frame)
RCT_NOT_IMPLEMENTED(- (instancetype)initWithCoder:coder)

- (void)insertReactSubview:(UIView *)view atIndex:(NSInteger)atIndex
{
    RCTLogError(@"AdMob Banner cannot have any subviews");
    return;
}

- (void)removeReactSubview:(UIView *)subview
{
    RCTLogError(@"AdMob Banner cannot have any subviews");
    return;
}

- (GADAdSize)getAdSizeFromString:(NSString *)bannerSize
{
    if ([bannerSize isEqualToString:@"banner"]) {
        return kGADAdSizeBanner;
    } else if ([bannerSize isEqualToString:@"largeBanner"]) {
        return kGADAdSizeLargeBanner;
    } else if ([bannerSize isEqualToString:@"mediumRectangle"]) {
        return kGADAdSizeMediumRectangle;
    } else if ([bannerSize isEqualToString:@"fullBanner"]) {
        return kGADAdSizeFullBanner;
    } else if ([bannerSize isEqualToString:@"leaderboard"]) {
        return kGADAdSizeLeaderboard;
    } else if ([bannerSize isEqualToString:@"smartBannerPortrait"]) {
        return kGADAdSizeSmartBannerPortrait;
    } else if ([bannerSize isEqualToString:@"smartBannerLandscape"]) {
        return kGADAdSizeSmartBannerLandscape;
    }
    else {
        return kGADAdSizeBanner;
    }
}

-(void)loadBanner {
    if (_adUnitID && _bannerSize) {
         NSLog(@"---- DFP TAG ---- (%@)", [NSString stringWithFormat:@"\"%@\"",_adUnitID]);
        GADAdSize size = [self getAdSizeFromString:_bannerSize];
        _bannerView = [[DFPBannerView alloc] initWithAdSize:size];
        [_bannerView setAppEventDelegate:self]; //added Admob event dispatch listener
        if(!CGRectEqualToRect(self.bounds, _bannerView.bounds)) {
            [_eventDispatcher
             sendInputEventWithName:@"onSizeChange"
             body:@{
                    @"target": self.reactTag,
                    @"width": [NSNumber numberWithFloat: _bannerView.bounds.size.width],
                    @"height": [NSNumber numberWithFloat: _bannerView.bounds.size.height]
                    }];
        }
        _bannerView.delegate = self;
        _bannerView.adUnitID = [NSString stringWithFormat:@"\"%@\"",_adUnitID];
        _bannerView.rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
        DFPRequest *request = [DFPRequest request];
        if(_targeting) {
			NSArray *array = [_targeting componentsSeparatedByString:@"|"];
            int i;
            for (i = 0 ; i < [array count] ; i++) {
                id objet = [array objectAtIndex:i];
                if ([objet length]>0 && objet){
                    NSArray *array2 = [objet componentsSeparatedByString:@":"];
                    if ([array2 count]>1){
                        NSString *key =[array2 objectAtIndex:0];
                        NSString *valeur =[array2 objectAtIndex:1];
                        if ([valeur length]>0 && ![valeur isEqual:@"[]"]){
                            NSLog(@"---- DFP TARGETING ---- (%@, %@)", [NSString stringWithFormat:@"\"%@\"",key]  , [NSString stringWithFormat:@"\"%@\"",valeur]);
                           
                            
                            request.customTargeting = @{[NSString stringWithFormat:@"\"%@\"",key]: [NSString stringWithFormat:@"\"%@\"",valeur]};
                        }
                    }
                }
            }
		}
		
        [_bannerView loadRequest:request];
    }
}


- (void)adView:(DFPBannerView *)banner
didReceiveAppEvent:(NSString *)name
      withInfo:(NSString *)info {
    NSLog(@"Received app event (%@, %@)", name, info);
    NSMutableDictionary *myDictionary = [[NSMutableDictionary alloc] init];
    myDictionary[name] = info;
    [_eventDispatcher sendInputEventWithName:@"onAdmobDispatchAppEvent" body:@{ @"target": self.reactTag, name: info }];
}

- (void)setBannerSize:(NSString *)bannerSize
{
    if(![bannerSize isEqual:_bannerSize]) {
        _bannerSize = bannerSize;
        if (_bannerView) {
            [_bannerView removeFromSuperview];
        }
        [self loadBanner];
    }
}



- (void)setAdUnitID:(NSString *)adUnitID
{
    if(![adUnitID isEqual:_adUnitID]) {
        _adUnitID = adUnitID;
        if (_bannerView) {
            [_bannerView removeFromSuperview];
        }
        
        [self loadBanner];
    }
}

- (void)setTargeting:(NSString *)targeting
{
    if(![targeting isEqual:_targeting]) {
        _targeting = targeting;
        if (_bannerView) {
            [_bannerView removeFromSuperview];
        }
        
        [self loadBanner];
    }
}

-(void)layoutSubviews
{
    [super layoutSubviews ];
    
    _bannerView.frame = CGRectMake(
                                   self.bounds.origin.x,
                                   self.bounds.origin.x,
                                   _bannerView.frame.size.width,
                                   _bannerView.frame.size.height);
    [self addSubview:_bannerView];
}

- (void)removeFromSuperview
{
    _eventDispatcher = nil;
    [super removeFromSuperview];
}

/// Tells the delegate an ad request loaded an ad.
- (void)adViewDidReceiveAd:(DFPBannerView *)adView {
    [_eventDispatcher sendInputEventWithName:@"onAdViewDidReceiveAd" body:@{ @"target": self.reactTag }];
}

/// Tells the delegate an ad request failed.
- (void)adView:(DFPBannerView *)adView
didFailToReceiveAdWithError:(GADRequestError *)error {
    [_eventDispatcher sendInputEventWithName:@"onDidFailToReceiveAdWithError" body:@{ @"target": self.reactTag, @"error": [error localizedDescription] }];
}

/// Tells the delegate that a full screen view will be presented in response
/// to the user clicking on an ad.
- (void)adViewWillPresentScreen:(DFPBannerView *)adView {
    [_eventDispatcher sendInputEventWithName:@"onAdViewWillPresentScreen" body:@{ @"target": self.reactTag }];
}

/// Tells the delegate that the full screen view will be dismissed.
- (void)adViewWillDismissScreen:(DFPBannerView *)adView {
    [_eventDispatcher sendInputEventWithName:@"onAdViewWillDismissScreen" body:@{ @"target": self.reactTag }];
}

/// Tells the delegate that the full screen view has been dismissed.
- (void)adViewDidDismissScreen:(DFPBannerView *)adView {
    [_eventDispatcher sendInputEventWithName:@"onAdViewDidDismissScreen" body:@{ @"target": self.reactTag }];
}

/// Tells the delegate that a user click will open another app (such as
/// the App Store), backgrounding the current app.
- (void)adViewWillLeaveApplication:(DFPBannerView *)adView {
    [_eventDispatcher sendInputEventWithName:@"onAdViewWillLeaveApplication" body:@{ @"target": self.reactTag }];
}

@end
