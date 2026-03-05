import Foundation

#if os(iOS)
import FamilyControls
import ManagedSettings
import DeviceActivity
import Combine
#endif

/// Manages Screen Time authorization for the FamilyControls entitlement.
///
/// On iOS: calls `AuthorizationCenter.shared.requestAuthorization(for: .individual)` and
/// observes `$authorizationStatus` to drive deauthorization cleanup.
///
/// On macOS (host tests): FamilyControls APIs are compile-guarded; status stays `.notDetermined`
/// and cleanup seam is exercised via `AuthorizationCleanupHandler` injection.
///
/// - Important: `requestAuthorization()` must only be called from the main app process,
///   never from an extension target (FamilyControls constraint).
public final class AuthorizationManager {

    // MARK: - State

    /// Current authorization status. Defaults to `.notDetermined` on non-iOS hosts.
    public private(set) var currentStatus: AuthorizationStatus = .notDetermined

    // MARK: - Cleanup seam

    private let cleanupHandler: AuthorizationCleanupHandler?

    #if os(iOS)
    private var cancellables = Set<AnyCancellable>()
    #endif

    // MARK: - Init

    /// Production initializer — no explicit cleanup handler needed; real cleanup uses ManagedSettings directly.
    public convenience init() {
        self.init(cleanupHandler: nil)
    }

    /// Testable initializer — inject a mock cleanup handler.
    public init(cleanupHandler: AuthorizationCleanupHandler?) {
        self.cleanupHandler = cleanupHandler
        setupDeauthorizationObserver()
    }

    // MARK: - Public API

    /// Requests FamilyControls authorization from the user.
    ///
    /// On iOS: presents system authorization sheet via `AuthorizationCenter`.
    /// On macOS: throws `AuthorizationError.familyControlsUnavailable`.
    ///
    /// - Throws: `AuthorizationError` on non-iOS platforms or system-level denial.
    public func requestAuthorization() async throws {
        #if os(iOS)
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            currentStatus = mapFamilyControlsStatus(AuthorizationCenter.shared.authorizationStatus)
        } catch {
            currentStatus = .denied
            throw AuthorizationError.denied
        }
        #else
        throw AuthorizationError.familyControlsUnavailable
        #endif
    }

    // MARK: - Test seam (for deterministic unit testing)

    /// Injects a simulated status change. Used exclusively by tests to exercise cleanup logic
    /// without requiring FamilyControls at runtime.
    ///
    /// - Parameter status: The status to apply. Triggers cleanup if `.denied`.
    public func simulateStatusChange(to status: AuthorizationStatus) {
        currentStatus = status
        if status == .denied {
            triggerDeauthorizationCleanup()
        }
    }

    // MARK: - Private helpers

    private func setupDeauthorizationObserver() {
        #if os(iOS)
        AuthorizationCenter.shared.$authorizationStatus
            .sink { [weak self] familyStatus in
                guard let self else { return }
                let mapped = self.mapFamilyControlsStatus(familyStatus)
                self.currentStatus = mapped
                if mapped == .denied {
                    self.triggerDeauthorizationCleanup()
                }
            }
            .store(in: &cancellables)
        #endif
    }

    /// Runs the cleanup chain when authorization is revoked.
    /// Idempotent — safe to call multiple times.
    private func triggerDeauthorizationCleanup() {
        if let handler = cleanupHandler {
            // Test path: delegate to injected mock
            handler.clearAllSettings()
            handler.stopAllMonitoring()
        } else {
            // Production path: call real system APIs directly (iOS only)
            #if os(iOS)
            ManagedSettingsStore().clearAllSettings()
            DeviceActivityCenter().stopMonitoring()
            #endif
        }
    }

    #if os(iOS)
    private func mapFamilyControlsStatus(_ status: FamilyControls.AuthorizationStatus) -> AuthorizationStatus {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .approved:
            return .approved
        case .denied:
            return .denied
        @unknown default:
            return .notDetermined
        }
    }
    #endif
}
