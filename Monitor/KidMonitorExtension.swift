import DeviceActivity

/// Runs in the background (even when the app is closed) and enforces the time limit.
class KidMonitorExtension: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        RestrictionEngine.handleIntervalStart()
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        RestrictionEngine.handleEvent(event.rawValue)
    }
}
