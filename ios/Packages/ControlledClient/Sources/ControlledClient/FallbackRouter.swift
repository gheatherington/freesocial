import Foundation

/// Routes users to the native platform app when the controlled client cannot satisfy a request.
/// Phase 2 stub — native app URL routing implemented in future phase.
public struct FallbackRouter {
    public init() {}

    /// Opens the native app for the given social provider.
    /// - Parameter provider: The social provider whose native app should be opened.
    /// - Returns: `true` if the native app was successfully opened; `false` if the route is unsupported.
    @discardableResult
    public func routeToNativeApp(for provider: any SocialProvider) -> Bool {
        // TODO: Implement deep link routing to native Instagram/TikTok app.
        // Use UIApplication.shared.open with provider-specific URL schemes.
        // Verify URL scheme availability before attempting to open.
        // Phase 2 stub: always returns false until URL routing is implemented.
        return false
    }
}
