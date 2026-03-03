import Foundation

/// Routes users to the native platform app when the controlled client cannot satisfy a request.
/// Phase 2 stub — native app URL routing implemented in future phase.
public struct FallbackRouter {
    public init() {}

    /// Opens the native app for the given social provider.
    /// - Parameter provider: The social provider whose native app should be opened.
    public func routeToNativeApp(for provider: any SocialProvider) {
        // TODO: Implement deep link routing to native Instagram/TikTok app.
        // Use UIApplication.shared.open with provider-specific URL schemes.
        // Verify URL scheme availability before attempting to open.
    }
}
