import Foundation
import PolicyStore

#if os(iOS)
import DeviceActivity
#endif

// MARK: - MonitoredPlatform

/// The social platforms that ActivityScheduler can enforce daily limits on.
public enum MonitoredPlatform: String, CaseIterable, Hashable {
    case instagram
    case tiktok
}

// MARK: - ActivitySchedulerError

/// Errors thrown by ActivityScheduler when input is invalid.
public enum ActivitySchedulerError: Error, Equatable {
    /// A platform limit value of zero or below was supplied.
    case invalidDailyLimit(platform: MonitoredPlatform, minutes: Int)
    /// A required platform entry was not included in the platformLimits dictionary.
    case missingPlatformLimit(platform: MonitoredPlatform)
}

// MARK: - MonitoringStartResult

/// The outcome of calling `startMonitoring(platformLimits:)`.
public enum MonitoringStartResult: Equatable {
    /// Monitoring was successfully registered with DeviceActivityCenter.
    case started
    /// No app tokens are persisted in FamilyActivitySelectionStore; monitoring skipped.
    case noTokensSelected
}

// MARK: - MonitoringConfiguration

/// Pure-value configuration that describes a daily monitoring schedule and per-platform events.
/// Returned by `buildMonitoringConfiguration` for deterministic unit testing.
public struct MonitoringConfiguration {
    public struct ScheduleComponents {
        public let intervalStart: DateComponents
        public let intervalEnd: DateComponents
        public let repeats: Bool
    }

    public struct EventThreshold {
        /// Threshold duration as a `DateComponents` value (minute field set).
        public let threshold: DateComponents
    }

    public let schedule: ScheduleComponents
    /// Keyed by `DeviceActivityEvent.Name` raw value string (matching ScreenTimeEngine.EventName constants).
    public let events: [String: EventThreshold]
}

// MARK: - ActivityScheduler

/// Manages DeviceActivity monitoring schedules for per-platform daily enforcement.
///
/// Scheduling and authorization calls must only originate from the main app process.
/// Extensions react to callbacks; they do not call `startMonitoring`.
public final class ActivityScheduler {

    // MARK: - Dependencies

    private let selectionStore: FamilyActivitySelectionStore

    // MARK: - Init

    /// Production initializer — reads token selection from the shared App Group.
    public convenience init() {
        self.init(suiteName: AppGroup.suiteName)
    }

    /// Testable initializer — accepts an explicit suiteName for isolated test UserDefaults.
    public init(suiteName: String) {
        self.selectionStore = FamilyActivitySelectionStore(suiteName: suiteName)
    }

    // MARK: - Configuration builder (pure, testable on macOS)

    /// Builds and validates a `MonitoringConfiguration` from the given per-platform limits.
    ///
    /// - Parameter platformLimits: Daily usage limits in minutes keyed by `MonitoredPlatform`.
    ///   Both `.instagram` and `.tiktok` entries are required.
    /// - Throws: `ActivitySchedulerError.missingPlatformLimit` if a platform is absent.
    /// - Throws: `ActivitySchedulerError.invalidDailyLimit` if any limit is ≤ 0.
    public func buildMonitoringConfiguration(
        platformLimits: [MonitoredPlatform: Int]
    ) throws -> MonitoringConfiguration {
        // Validate all required platforms are present and have valid limits.
        for platform in MonitoredPlatform.allCases {
            guard let minutes = platformLimits[platform] else {
                throw ActivitySchedulerError.missingPlatformLimit(platform: platform)
            }
            guard minutes > 0 else {
                throw ActivitySchedulerError.invalidDailyLimit(platform: platform, minutes: minutes)
            }
        }

        // Build daily midnight-to-midnight repeating schedule.
        var startComponents = DateComponents()
        startComponents.hour = 0
        startComponents.minute = 0

        var endComponents = DateComponents()
        endComponents.hour = 23
        endComponents.minute = 59

        let schedule = MonitoringConfiguration.ScheduleComponents(
            intervalStart: startComponents,
            intervalEnd: endComponents,
            repeats: true
        )

        // Map platforms to named event thresholds.
        var events: [String: MonitoringConfiguration.EventThreshold] = [:]

        let instagramMinutes = platformLimits[.instagram]!
        var instagramThreshold = DateComponents()
        instagramThreshold.minute = instagramMinutes
        events[ScreenTimeEngine.EventName.instagramDailyLimit] = MonitoringConfiguration.EventThreshold(
            threshold: instagramThreshold
        )

        let tiktokMinutes = platformLimits[.tiktok]!
        var tiktokThreshold = DateComponents()
        tiktokThreshold.minute = tiktokMinutes
        events[ScreenTimeEngine.EventName.tiktokDailyLimit] = MonitoringConfiguration.EventThreshold(
            threshold: tiktokThreshold
        )

        return MonitoringConfiguration(schedule: schedule, events: events)
    }

    // MARK: - Start/Stop Monitoring

    /// Registers daily per-platform monitoring with DeviceActivityCenter.
    ///
    /// Performs stop-then-start for idempotent re-registration.
    /// Returns `.noTokensSelected` without registering if no app tokens are persisted.
    ///
    /// - Parameter platformLimits: Daily usage limits in minutes keyed by `MonitoredPlatform`.
    ///   Both `.instagram` and `.tiktok` entries are required (throws on invalid input).
    /// - Returns: `.started` on success, `.noTokensSelected` when no tokens persisted.
    @discardableResult
    public func startMonitoring(platformLimits: [MonitoredPlatform: Int]) async -> MonitoringStartResult {
        // Guard: require valid configuration (ignore invalid-limit errors here by building first).
        guard (try? buildMonitoringConfiguration(platformLimits: platformLimits)) != nil else {
            return .noTokensSelected
        }

        // Guard: require persisted token selection.
        guard selectionStore.hasSelection else {
            return .noTokensSelected
        }

        #if os(iOS)
        let center = DeviceActivityCenter()
        let activityName = DeviceActivityName(ScreenTimeEngine.dailyActivityName)

        // Stop any existing monitoring to ensure idempotent restart.
        center.stopMonitoring([activityName])

        guard let config = try? buildMonitoringConfiguration(platformLimits: platformLimits) else {
            return .noTokensSelected
        }

        let schedule = DeviceActivitySchedule(
            intervalStart: config.schedule.intervalStart,
            intervalEnd: config.schedule.intervalEnd,
            repeats: config.schedule.repeats
        )

        var deviceActivityEvents: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
        for (eventNameString, eventConfig) in config.events {
            let eventName = DeviceActivityEvent.Name(eventNameString)
            let event = DeviceActivityEvent(threshold: eventConfig.threshold)
            deviceActivityEvents[eventName] = event
        }

        do {
            try center.startMonitoring(activityName, during: schedule, events: deviceActivityEvents)
        } catch {
            // startMonitoring can throw if activity is already monitored or schedule is invalid.
            // We performed stop first, so this indicates an unexpected error — log and return.
            return .noTokensSelected
        }
        #endif

        return .started
    }

    /// Stops all active monitoring for the daily activity.
    /// Safe to call when no monitoring is active (idempotent).
    public func stopMonitoring() {
        #if os(iOS)
        let center = DeviceActivityCenter()
        let activityName = DeviceActivityName(ScreenTimeEngine.dailyActivityName)
        center.stopMonitoring([activityName])
        #endif
    }
}
