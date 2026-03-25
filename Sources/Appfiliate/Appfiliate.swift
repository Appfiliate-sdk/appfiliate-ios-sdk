// Appfiliate iOS SDK
// Lightweight install attribution for mobile app affiliate marketing.
// https://appfiliate.io

import Foundation
import UIKit

public final class Appfiliate {

    // MARK: - Configuration

    private static var appId: String?
    private static var apiKey: String?
    private static var apiBase = "https://us-central1-appfiliate-5a18b.cloudfunctions.net/api"
    private static var isConfigured = false
    private static var pendingUserId: String?
    private static var attributionInFlight = false

    /// Configure Appfiliate with your app credentials.
    /// Call this once in your App init or AppDelegate didFinishLaunching.
    ///
    /// ```swift
    /// Appfiliate.configure(appId: "app_xxx", apiKey: "key_xxx")
    /// ```
    public static func configure(appId: String, apiKey: String) {
        self.appId = appId
        self.apiKey = apiKey
        self.isConfigured = true
    }

    /// Override the API base URL (for testing/development).
    public static func setAPIBase(_ url: String) {
        self.apiBase = url
    }

    // MARK: - Install Attribution

    /// Track app install attribution. Call once on first app launch, after configure().
    /// Automatically runs only once per install.
    ///
    /// ```swift
    /// Appfiliate.trackInstall()
    /// ```
    public static func trackInstall(completion: ((AttributionResult) -> Void)? = nil) {
        guard isConfigured else {
            print("[Appfiliate] Error: call Appfiliate.configure() before trackInstall()")
            return
        }

        let key = "appfiliate_install_tracked"
        if UserDefaults.standard.bool(forKey: key) {
            // Already tracked — read cached result
            if let cached = cachedAttribution() {
                completion?(cached)
                flushPendingUserId()
            }
            return
        }

        attributionInFlight = true

        let payload: [String: Any] = [
            "app_id": appId ?? "",
            "platform": "ios",
            "device_model": deviceModel(),
            "os_version": UIDevice.current.systemVersion,
            "screen_width": Int(UIScreen.main.bounds.width),
            "screen_height": Int(UIScreen.main.bounds.height),
            "screen_scale": Int(UIScreen.main.scale),
            "timezone": TimeZone.current.identifier,
            "language": Locale.preferredLanguages.first ?? "unknown",
            "languages": Locale.preferredLanguages,
            "hw_concurrency": ProcessInfo.processInfo.activeProcessorCount,
            "idfv": UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
            "sdk_version": sdkVersion
        ]

        post(endpoint: "/v1/attribution", payload: payload) { result in
            switch result {
            case .success(let json):
                let attribution = AttributionResult(
                    matched: json["matched"] as? Bool ?? false,
                    attributionId: json["attribution_id"] as? String,
                    confidence: json["confidence"] as? Double ?? 0,
                    method: json["method"] as? String ?? "unknown",
                    clickId: json["click_id"] as? String
                )

                // Cache the result
                UserDefaults.standard.set(true, forKey: key)
                if let id = attribution.attributionId {
                    UserDefaults.standard.set(id, forKey: "appfiliate_attribution_id")
                }
                UserDefaults.standard.set(attribution.matched, forKey: "appfiliate_matched")

                print("[Appfiliate] Install attribution: matched=\(attribution.matched), confidence=\(attribution.confidence), method=\(attribution.method)")
                attributionInFlight = false
                completion?(attribution)
                flushPendingUserId()

            case .failure(let error):
                print("[Appfiliate] Attribution error: \(error.localizedDescription)")
                attributionInFlight = false
                // Don't mark as tracked so it retries next launch
                completion?(AttributionResult(matched: false, attributionId: nil, confidence: 0, method: "error", clickId: nil))
            }
        }
    }

    // MARK: - Purchase Tracking

    /// Track an in-app purchase attributed to the install.
    ///
    /// ```swift
    /// Appfiliate.trackPurchase(
    ///     productId: "premium_monthly",
    ///     revenue: 9.99,
    ///     currency: "USD",
    ///     transactionId: "txn_123"
    /// )
    /// ```
    public static func trackPurchase(
        productId: String,
        revenue: Double,
        currency: String = "USD",
        transactionId: String? = nil
    ) {
        guard isConfigured else {
            print("[Appfiliate] Error: call Appfiliate.configure() before trackPurchase()")
            return
        }

        guard let attributionId = UserDefaults.standard.string(forKey: "appfiliate_attribution_id") else {
            print("[Appfiliate] No attribution ID found. Install may not have been attributed.")
            return
        }

        var payload: [String: Any] = [
            "app_id": appId ?? "",
            "attribution_id": attributionId,
            "product_id": productId,
            "revenue": revenue,
            "currency": currency,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "sdk_version": sdkVersion
        ]

        if let transactionId {
            payload["transaction_id"] = transactionId
        }

        post(endpoint: "/v1/purchases", payload: payload) { result in
            switch result {
            case .success:
                print("[Appfiliate] Purchase tracked: \(productId) \(revenue) \(currency)")
            case .failure(let error):
                print("[Appfiliate] Purchase tracking error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Public Types

    public struct AttributionResult {
        public let matched: Bool
        public let attributionId: String?
        public let confidence: Double
        public let method: String
        public let clickId: String?
    }

    // MARK: - Helpers

    /// Check if this install was attributed to a creator
    public static var isAttributed: Bool {
        UserDefaults.standard.bool(forKey: "appfiliate_matched")
    }

    /// The attribution ID for this install (nil if not attributed)
    public static var attributionId: String? {
        UserDefaults.standard.string(forKey: "appfiliate_attribution_id")
    }

    /// Link an external user ID (e.g. RevenueCat appUserID) to this install's attribution.
    /// This allows server-side integrations (webhooks) to attribute purchases automatically.
    ///
    /// ```swift
    /// Appfiliate.setUserId(Purchases.shared.appUserID)
    /// ```
    public static func setUserId(_ userId: String) {
        guard isConfigured else {
            print("[Appfiliate] Error: call Appfiliate.configure() before setUserId()")
            return
        }

        // If attribution is still in flight, queue the user ID and send it when attribution completes
        if attributionInFlight {
            pendingUserId = userId
            return
        }

        guard let attributionId = UserDefaults.standard.string(forKey: "appfiliate_attribution_id") else {
            // Attribution finished but wasn't matched — queue in case of retry on next launch
            pendingUserId = userId
            return
        }

        sendUserId(userId, attributionId: attributionId)
    }

    private static func sendUserId(_ userId: String, attributionId: String) {
        let payload: [String: Any] = [
            "app_id": appId ?? "",
            "attribution_id": attributionId,
            "user_id": userId,
            "sdk_version": sdkVersion
        ]

        post(endpoint: "/v1/user-id", payload: payload) { result in
            switch result {
            case .success:
                print("[Appfiliate] User ID linked: \(userId)")
            case .failure(let error):
                print("[Appfiliate] setUserId error: \(error.localizedDescription)")
            }
        }
    }

    private static func flushPendingUserId() {
        guard let userId = pendingUserId else { return }
        pendingUserId = nil

        guard let attributionId = UserDefaults.standard.string(forKey: "appfiliate_attribution_id") else { return }
        sendUserId(userId, attributionId: attributionId)
    }

    // MARK: - Private

    private static let sdkVersion = "1.0.0"

    private static func deviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0) ?? "unknown"
            }
        }
    }

    private static func cachedAttribution() -> AttributionResult? {
        guard UserDefaults.standard.bool(forKey: "appfiliate_install_tracked") else { return nil }
        return AttributionResult(
            matched: UserDefaults.standard.bool(forKey: "appfiliate_matched"),
            attributionId: UserDefaults.standard.string(forKey: "appfiliate_attribution_id"),
            confidence: 0,
            method: "cached",
            clickId: nil
        )
    }

    private static func post(
        endpoint: String,
        payload: [String: Any],
        completion: @escaping (Result<[String: Any], Error>) -> Void
    ) {
        guard let url = URL(string: apiBase + endpoint) else { return }
        guard let body = try? JSONSerialization.data(withJSONObject: payload) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue(appId, forHTTPHeaderField: "X-App-ID")
        request.timeoutInterval = 10

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                completion(.failure(NSError(domain: "Appfiliate", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                return
            }
            completion(.success(json))
        }.resume()
    }
}
