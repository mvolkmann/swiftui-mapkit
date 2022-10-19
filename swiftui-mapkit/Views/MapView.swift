import Combine
import MapKit
import SwiftUI

struct MapView: UIViewRepresentable {
    private var counter = 0

    static let londonLatitude = 51.501
    static let londonLongitude = -0.1425
    private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: Self.londonLatitude,
            longitude: Self.londonLongitude
        ),
        span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
    )
    @EnvironmentObject private var mapSettings: MapSettings

    func makeUIView(context _: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.region = mapRegion
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context _: Context) {
        switch mapSettings.mapType {
        case 0:
            uiView.preferredConfiguration = MKStandardMapConfiguration(
                elevationStyle: elevationStyle(),
                emphasisStyle: emphasisStyle()
            )
        case 1:
            uiView.preferredConfiguration = MKImageryMapConfiguration(
                elevationStyle: elevationStyle()
            )
        case 2:
            uiView.preferredConfiguration = MKHybridMapConfiguration(
                elevationStyle: elevationStyle()
            )
        default:
            break
        }
    }

    private func elevationStyle() -> MKMapConfiguration.ElevationStyle {
        mapSettings.showElevation == 0 ?
            MKMapConfiguration.ElevationStyle.realistic :
            MKMapConfiguration.ElevationStyle.flat
    }

    private func emphasisStyle() -> MKStandardMapConfiguration.EmphasisStyle {
        mapSettings.showEmphasisStyle == 0 ?
            MKStandardMapConfiguration.EmphasisStyle.default :
            MKStandardMapConfiguration.EmphasisStyle.muted
    }
}
