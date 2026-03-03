/// EscalationLevel represents the current cooldown state of the content feed.
/// Escalates from baseline through two cooldown tiers to full lockdown.
public enum EscalationLevel: String, Codable, CaseIterable {
    case baseline
    case cooldown1
    case cooldown2
    case lockdown
}
