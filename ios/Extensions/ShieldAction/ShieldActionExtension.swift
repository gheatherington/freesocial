import ManagedSettings
import PolicyStore

final class ShieldActionExtension: ShieldActionDelegate {
    override func handle(
        action: ShieldAction,
        for application: Application,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        // Stub: defer to PolicyStore for action decision
        // Phase 3 will implement unlock request flow here
        completionHandler(.close)
    }

    override func handle(
        action: ShieldAction,
        for webDomain: WebDomain,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        completionHandler(.close)
    }
}
