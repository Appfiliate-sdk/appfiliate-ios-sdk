# Appfiliate iOS SDK

Creator attribution SDK for mobile app affiliate marketing. Track which creators, influencers, and campaigns drive installs and revenue for your iOS app — without IDFA.

**[Website](https://appfiliate.io)** | **[Documentation](https://docs.appfiliate.io)** | **[Blog](https://appfiliate.io/blog)** | **[Sign Up Free](https://app.appfiliate.io/signup)**

## Features

- 3-line integration — configure, track, done
- No IDFA required — no ATT prompt needed
- Per-creator install and revenue attribution
- Built-in creator dashboards
- Webhook integrations with RevenueCat, Superwall, Adapty, Qonversion, and Stripe
- Under 200KB, zero external dependencies

## Installation

Add the package in Xcode:

1. **File → Add Package Dependencies**
2. Paste the repository URL:
   ```
   https://github.com/Appfiliate-sdk/appfiliate-ios-sdk
   ```
3. Select version `1.0.0` or later

## Quick Start

Three lines of code. Add to your App init or AppDelegate:

```swift
import Appfiliate

Appfiliate.configure(appId: "APP_ID", apiKey: "API_KEY")
Appfiliate.trackInstall()
Appfiliate.setUserId(Purchases.shared.appUserID) // optional — for webhook integrations
```

That's it. The SDK automatically:
- Sends device signals on first launch (only runs once per install)
- Matches the install to a tracking link click
- Caches the result locally
- Queues the user ID mapping if called before attribution completes

Get your `appId` and `apiKey` from the [Appfiliate dashboard](https://app.appfiliate.io).

## Track Purchases

Attribute in-app purchases to the creator who drove the install:

```swift
Appfiliate.trackPurchase(
    productId: "premium_monthly",
    revenue: 9.99,
    currency: "USD",
    transactionId: transaction.id
)
```

Or use [webhook integrations](https://docs.appfiliate.io) with RevenueCat, Superwall, Adapty, Qonversion, or Stripe for automatic purchase tracking.

## Check Attribution

```swift
if Appfiliate.isAttributed {
    print("Attribution ID: \(Appfiliate.attributionId ?? "none")")
}
```

## How It Works

1. A creator shares a tracking link
2. User clicks → our server records signals → redirects to App Store
3. User installs and opens the app
4. The SDK calls `trackInstall()` on first launch
5. Our server matches the install to the click (deterministic on Android, fingerprint on iOS)
6. Attribution result is returned and cached

Learn more: [How mobile attribution works without IDFA](https://appfiliate.io/blog/mobile-app-install-attribution-without-idfa)

## Privacy

- **No IDFA** — no App Tracking Transparency prompt required
- **No cross-app tracking** — only matches clicks to installs for your app
- Uses only standard device information (model, OS version, locale, timezone)
- IDFV (Identifier for Vendor) is used for deduplication only
- Fully compliant with App Store guidelines

## Requirements

- iOS 15.0+
- Swift 5.9+
- Xcode 15+

## Resources

- [Getting started guide](https://docs.appfiliate.io/quick-start)
- [How to set up an affiliate program for your app](https://appfiliate.io/blog/how-to-set-up-affiliate-program-mobile-app)
- [Appfiliate vs AppsFlyer vs Branch](https://appfiliate.io/blog/appfiliate-vs-appsflyer-vs-branch)
- [Creator attribution SDK explained](https://appfiliate.io/blog/creator-attribution-sdk)

## License

MIT
