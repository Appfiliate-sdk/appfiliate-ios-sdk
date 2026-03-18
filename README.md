# Appfiliate iOS SDK

Lightweight install attribution for mobile app affiliate marketing.

## Installation

Add the package in Xcode:

1. **File → Add Package Dependencies**
2. Paste the repository URL:
   ```
   https://github.com/yourusername/appfiliate-ios-sdk
   ```
3. Select version `1.0.0` or later

## Quick Start

**Two lines of code.** Add to your App init or AppDelegate:

```swift
import Appfiliate

@main
struct MyApp: App {
    init() {
        Appfiliate.configure(appId: "app_xxx", apiKey: "key_xxx")
        Appfiliate.trackInstall()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

That's it. The SDK automatically:
- Sends device signals on first launch (only runs once per install)
- Matches the install to a tracking link click
- Caches the result locally

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

## Check Attribution

```swift
if Appfiliate.isAttributed {
    print("This install was attributed!")
    print("Attribution ID: \(Appfiliate.attributionId ?? "none")")
}
```

## Attribution Result Callback

```swift
Appfiliate.trackInstall { result in
    print("Matched: \(result.matched)")
    print("Confidence: \(result.confidence)")
    print("Method: \(result.method)")
}
```

## How It Works

1. A creator shares a tracking link (e.g. `track.appfiliate.io/c/abc123`)
2. User clicks → our server records IP, User-Agent, and other signals → redirects to App Store
3. User installs and opens the app
4. The SDK sends device signals to our server on first launch
5. Our server matches the install to the click
6. Attribution result is returned and cached

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

## License

MIT
