import CoreLocation
import Foundation
import UserNotifications

final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var currentCoordinate: CLLocationCoordinate2D?
    @Published private(set) var arrivedPlaceID: UUID?
    @Published private(set) var statusMessage = ""

    var isAuthorized: Bool {
        authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse
    }

    private let manager = CLLocationManager()
    private var activeSession: OutingSession?
    private var places: [GowithPlace] = []
    private let regionPrefix = "gowith."

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.distanceFilter = 10
        authorizationStatus = manager.authorizationStatus
    }

    func requestCurrentLocation() {
        authorizationStatus = manager.authorizationStatus
        switch authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            statusMessage = "允许定位后，可使用当前位置设置地点。"
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied, .restricted:
            statusMessage = "请在系统设置中允许 Gowith 使用定位，或在地图上点选地点。"
        @unknown default:
            statusMessage = "当前无法获取定位。"
        }
    }

    func requestCurrentLocationIfNeeded() {
        guard isAuthorized || authorizationStatus == .notDetermined else { return }
        requestCurrentLocation()
    }

    func distance(to place: GowithPlace) -> CLLocationDistance? {
        guard let coordinate = currentCoordinate, let placeCoordinate = place.coordinate else { return nil }
        return CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            .distance(from: CLLocation(latitude: placeCoordinate.latitude, longitude: placeCoordinate.longitude))
    }

    func isInside(_ place: GowithPlace) -> Bool {
        guard let distance = distance(to: place) else { return false }
        return distance <= place.radius
    }

    func requestArrivalPermissions() {
        manager.requestAlwaysAuthorization()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func startMonitoring(session: OutingSession, places: [GowithPlace]) {
        activeSession = session
        self.places = places
        arrivedPlaceID = nil
        stopGowithRegions()

        guard session.status == .away else { return }
        guard let origin = places.first(where: { $0.id == session.originPlaceID }), origin.coordinate != nil else {
            statusMessage = "出发地点尚未设置地图位置；本次行程可继续，抵达时请手动确认。"
            return
        }

        authorizationStatus = manager.authorizationStatus
        switch authorizationStatus {
        case .authorizedAlways:
            armRegions(for: session, origin: origin)
        case .notDetermined, .authorizedWhenInUse:
            statusMessage = "需要允许始终定位，才能在后台发送到家提醒。"
            requestArrivalPermissions()
        case .denied, .restricted:
            statusMessage = "定位未开启；本次仍可出行，到达后可在地图页手动确认。"
        @unknown default:
            statusMessage = "定位暂不可用；到达后可手动确认。"
        }
        requestNotificationPermission()
    }

    func stopMonitoring() {
        activeSession = nil
        stopGowithRegions()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        // 授权通过后立即获取一次位置并开启前台持续更新：
        // 修复首次授权弹窗后不再请求定位、设置页拿不到坐标的问题。
        if isAuthorized {
            manager.startUpdatingLocation()
        }
        guard let activeSession, activeSession.status == .away,
              authorizationStatus == .authorizedAlways,
              let origin = places.first(where: { $0.id == activeSession.originPlaceID }) else { return }
        armRegions(for: activeSession, origin: origin)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentCoordinate = location.coordinate
        statusMessage = ""
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        statusMessage = "暂时无法获取当前位置；你仍可在地图上手动标记地点。"
    }

    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        manager.requestState(for: region)
    }

    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        if region.identifier == sourceIdentifier(for: activeSession), state == .outside {
            markOriginExited()
        } else if region.identifier.hasPrefix("\(regionPrefix)destination."), state == .inside {
            arrive(at: region.identifier)
        }
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard region.identifier == sourceIdentifier(for: activeSession) else { return }
        markOriginExited()
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard region.identifier.hasPrefix("\(regionPrefix)destination.") else { return }
        arrive(at: region.identifier)
    }

    private func armRegions(for session: OutingSession, origin: GowithPlace) {
        statusMessage = "离开「\(origin.name)」后，将监测其他已设置地点。"
        if session.hasExitedOrigin {
            monitorPlaces(for: session)
            return
        }
        guard let coordinate = origin.coordinate else { return }
        let region = CLCircularRegion(center: coordinate, radius: origin.radius, identifier: sourceIdentifier(for: session))
        region.notifyOnEntry = false
        region.notifyOnExit = true
        manager.startMonitoring(for: region)
    }

    private func markOriginExited() {
        guard let session = activeSession, !session.hasExitedOrigin else { return }
        session.hasExitedOrigin = true
        if let sourceRegion = manager.monitoredRegions.first(where: { $0.identifier == sourceIdentifier(for: session) }) {
            manager.stopMonitoring(for: sourceRegion)
        }
        onSessionChanged?()
        monitorPlaces(for: session)
    }

    private func monitorPlaces(for session: OutingSession) {
        stopGowithRegions()
        let candidates = places.filter { $0.coordinate != nil }
        for place in candidates.prefix(20) {
            guard let coordinate = place.coordinate else { continue }
            let region = CLCircularRegion(center: coordinate, radius: place.radius, identifier: destinationIdentifier(for: place.id))
            region.notifyOnEntry = true
            region.notifyOnExit = false
            manager.startMonitoring(for: region)
        }
        if candidates.isEmpty {
            statusMessage = "还没有设置地点的位置；可以稍后手动确认到达。"
        } else if candidates.count > 20 {
            statusMessage = "iOS 同时监听的地点数量有限，当前先监听前 20 个地点。"
        }
    }

    private func arrive(at identifier: String) {
        guard let rawID = identifier.split(separator: ".").last,
              let placeID = UUID(uuidString: String(rawID)),
              places.contains(where: { $0.id == placeID }),
              activeSession?.status == .away else { return }
        arrivedPlaceID = placeID
        statusMessage = "已进入地点范围，请确认是否抵达。"
        postArrivalNotification(placeID: placeID)
        stopGowithRegions()
    }

    private func sourceIdentifier(for session: OutingSession?) -> String {
        "\(regionPrefix)source.\(session?.id.uuidString ?? "none")"
    }

    private func destinationIdentifier(for placeID: UUID) -> String {
        "\(regionPrefix)destination.\(placeID.uuidString)"
    }

    private func stopGowithRegions() {
        for region in manager.monitoredRegions where region.identifier.hasPrefix(regionPrefix) {
            manager.stopMonitoring(for: region)
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    private func postArrivalNotification(placeID: UUID) {
        if UserDefaults.standard.object(forKey: "gowith.arrivalRemindersEnabled") != nil,
           !UserDefaults.standard.bool(forKey: "gowith.arrivalRemindersEnabled") {
            return
        }
        let placeName = places.first(where: { $0.id == placeID })?.name ?? "目的地"
        let content = UNMutableNotificationContent()
        content.title = "可能已经到达「\(placeName)」"
        content.body = "已进入「\(placeName)」，打开 Gowith 查看当前地点状态。"
        content.sound = .default
        let request = UNNotificationRequest(identifier: "gowith.arrival.\(placeID.uuidString)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    var onSessionChanged: (() -> Void)?
}
