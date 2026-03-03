import Foundation

// NOTE: Apply for com.apple.developer.family-controls entitlement before Phase 3.
// FamilyControls import is guarded to prevent CI build failures in environments
// where the framework is unavailable (e.g., macOS-hosted CI runners).
#if canImport(FamilyControls)
import FamilyControls
#endif

/// Manages Screen Time authorization for the FamilyControls entitlement.
/// Phase 2 stub — authorization flow implemented in Phase 3 when entitlement is active.
public final class AuthorizationManager {
    public init() {}

    /// Requests FamilyControls authorization from the user.
    /// - Throws: Authorization errors from FamilyControls framework (Phase 3).
    public func requestAuthorization() async throws {
        // Stub: call FamilyControls.AuthorizationCenter.shared.requestAuthorization() when entitlement is approved.
        // Phase 3 implementation: await AuthorizationCenter.shared.requestAuthorization(for: .individual)
    }
}
