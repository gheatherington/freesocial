import ManagedSettings
import ManagedSettingsUI
import UIKit

// NOTE: ShieldConfigurationDataSource is UIKit-backed.
// Do NOT attempt to return SwiftUI views from this extension.
// The ShieldConfiguration struct API accepts UIColor, UIImage, and Label structs only.
final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(
        shielding application: Application
    ) -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: .black,
            icon: UIImage(systemName: "eye.slash"),
            title: ShieldConfiguration.Label(
                text: "FreeSocial",
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: "This app is restricted",
                color: UIColor.secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "OK",
                color: .white
            ),
            primaryButtonBackgroundColor: .systemIndigo
        )
    }

    override func configuration(
        shielding webDomain: WebDomain
    ) -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: .black,
            title: ShieldConfiguration.Label(
                text: "FreeSocial",
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: "This site is restricted",
                color: UIColor.secondaryLabel
            )
        )
    }
}
