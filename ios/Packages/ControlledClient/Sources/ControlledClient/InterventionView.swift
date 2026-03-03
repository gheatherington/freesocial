import SwiftUI

/// Intervention prompt view shown when a session cooldown is triggered.
/// Displays hardcoded intervention copy from Phase 1 specification.
/// These strings are NOT localizable in Phase 2 — localization deferred to future phase.
public struct InterventionView: View {
    // Hardcoded intervention copy from Phase 1 specification.
    // Do NOT move to Localizable.strings until Phase 3+ localization work.
    private static let primaryMessage = "Session paused: take a 30-second break before loading more."
    private static let escalationWarning = "Repeated bypass attempts increase cooldown duration."

    public let message: String

    public init(message: String = InterventionView.primaryMessage) {
        self.message = message
    }

    public var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()
            VStack(spacing: 24) {
                Text(message)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 32)

                Text(InterventionView.escalationWarning)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 32)
            }
        }
    }
}
