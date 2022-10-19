import Combine
import MapKit
import SwiftUI

// For now we have to wrap an MKMapView in a UIViewRepresenatable
// in order to use the iOS 16 MapKit features in SwiftUI.
struct MapView: UIViewRepresentable {
    static let londonLatitude = 51.501
    static let londonLongitude = -0.1425

    var latitude = Self.londonLatitude
    var longitude = Self.londonLongitude
    var zoom: Double = 0.03

    @EnvironmentObject private var mapSettings: MapSettings

    func makeUIView(context _: Context) -> MKMapView {
        let mapRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: latitude,
                longitude: longitude
            ),
            span: MKCoordinateSpan(
                latitudeDelta: zoom,
                longitudeDelta: zoom
            )
        )

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
