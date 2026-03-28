// MapViewCoordinator.swift

import Foundation
import MapKit
import SwiftUI

class MapViewCoordinator: NSObject, MKMapViewDelegate {
    var parent: MapView
    var didSetInitialRegion = false

    init(_ parent: MapView) {
        self.parent = parent
    }

    // Renderer for overlays
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polygon = overlay as? SectionPolygon {
            let renderer = MKPolygonRenderer(polygon: polygon)
            configurePolygonRenderer(renderer, for: overlay)
            return renderer
        } else if let polyline = overlay as? SectionPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            configurePolylineRenderer(renderer, for: overlay)
            return renderer
        }
        return MKOverlayRenderer()
    }

    private enum CleaningUrgency {
        case urgent      // today or 1-3 days away, or 1 day past
        case upcoming    // 4-7 days away, or 2 days past
        case none        // >7 days away, >2 days past, or no date
    }

    private func urgency(for section: Section) -> CleaningUrgency {
        guard let date = section.dateForColoring() else { return .none }

        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfDate = calendar.startOfDay(for: date)
        let days = calendar.dateComponents([.day], from: startOfToday, to: startOfDate).day ?? 0

        if days >= 0 && days <= 3 {
            return .urgent
        } else if days >= 4 && days <= 7 {
            return .upcoming
        } else if days == -1 {
            return .urgent
        } else if days == -2 {
            return .upcoming
        }
        return .none
    }

    private func configurePolygonRenderer(_ renderer: MKPolygonRenderer, for overlay: MKOverlay) {
        if let polygon = overlay as? SectionPolygon, let section = polygon.section {
            switch urgency(for: section) {
            case .urgent:
                renderer.fillColor = UIColor.red.withAlphaComponent(0.5)
            case .upcoming:
                renderer.fillColor = UIColor.orange.withAlphaComponent(0.5)
            case .none:
                renderer.fillColor = UIColor.lightGray.withAlphaComponent(0.3)
            }
        } else {
            renderer.fillColor = UIColor.lightGray.withAlphaComponent(0.3)
        }

        renderer.strokeColor = UIColor.white.withAlphaComponent(0.5)
        renderer.lineWidth = 1.0
    }

    private func configurePolylineRenderer(_ renderer: MKPolylineRenderer, for overlay: MKOverlay) {
        if let polyline = overlay as? SectionPolyline, let section = polyline.section {
            switch urgency(for: section) {
            case .urgent:
                renderer.strokeColor = UIColor.red.withAlphaComponent(0.8)
            case .upcoming:
                renderer.strokeColor = UIColor.yellow.withAlphaComponent(0.8)
            case .none:
                renderer.strokeColor = UIColor.lightGray.withAlphaComponent(0.6)
            }
        } else {
            renderer.strokeColor = UIColor.lightGray.withAlphaComponent(0.6)
        }

        renderer.lineWidth = 2.0
    }

    // Handle tap gestures
    @objc func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        let location = gestureRecognizer.location(in: gestureRecognizer.view)
        if let mapView = gestureRecognizer.view as? MKMapView {
            let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
            // Iterate over overlays in reverse to check topmost overlays first
            for overlay in mapView.overlays.reversed() {
                if let renderer = mapView.renderer(for: overlay) as? MKOverlayPathRenderer {
                    let mapPoint = MKMapPoint(coordinate)
                    let point = renderer.point(for: mapPoint)
                    if renderer.path.contains(point) {
                        // Tap is inside the overlay
                        DispatchQueue.main.async {
                            if let sectionOverlay = overlay as? SectionOverlayProtocol, let section = sectionOverlay.section {
                                self.parent.locationManager.selectedSection = section
                            }
                        }
                        break
                    }
                }
            }
        }
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        DispatchQueue.main.async {
            self.parent.locationManager.region = mapView.region
        }
    }
}
