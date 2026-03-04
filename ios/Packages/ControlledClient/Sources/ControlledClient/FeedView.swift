import SwiftUI

/// Skeleton feed view for controlled content display.
/// Dark background matches app-wide dark-first color scheme.
/// Note: FamilyActivityPicker is used in ScreenTimeEngine, not here.
/// This view is responsible for rendering content items with intervention awareness.
public struct FeedView: View {
    public init() {}

    public var body: some View {
        ZStack {
            Color(red: 0.039, green: 0.039, blue: 0.039).ignoresSafeArea()
            List {
                // Empty state — content items will be populated by ControlledClient in future phase.
                Text("No posts yet")
                    .foregroundColor(.secondary)
                    .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }
}
