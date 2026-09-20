import CoreLocation
import Observation

@MainActor @Observable
final class LocationService: NSObject, @preconcurrency CLLocationManagerDelegate {
    private(set) var isLocating = false
    private(set) var message: String?
    private(set) var permissionDenied = false
    @ObservationIgnored var onLocation: ((CLLocationCoordinate2D) -> Void)?
    @ObservationIgnored private let manager = CLLocationManager()
    @ObservationIgnored private var timeout: Task<Void, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func request() {
        cancel()
        message = nil
        permissionDenied = false
        isLocating = true
        switch manager.authorizationStatus {
        case .notDetermined: manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse: locate()
        case .denied, .restricted: denied()
        @unknown default: denied()
        }
    }

    func cancel() {
        timeout?.cancel(); timeout = nil
        manager.stopUpdatingLocation()
        isLocating = false
    }

    private func locate() {
        manager.requestLocation()
        timeout?.cancel()
        timeout = Task { [weak self] in
            try? await Task.sleep(for: .seconds(20))
            guard !Task.isCancelled, let self, self.isLocating else { return }
            self.cancel()
            self.message = "Your location isn’t available yet. Try again or search for a city."
        }
    }

    private func denied() {
        cancel(); permissionDenied = true
        message = "Location access is off. Enable it in Settings, or search for a city."
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard isLocating else { return }
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse: locate()
        case .denied, .restricted: denied()
        default: break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isLocating, let fix = locations.last, fix.horizontalAccuracy >= 0,
              abs(fix.timestamp.timeIntervalSinceNow) < 120 else { return }
        cancel(); message = nil
        onLocation?(fix.coordinate)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard isLocating else { return }
        cancel()
        message = "Couldn’t determine your location. Try again or search for a city."
    }
}
