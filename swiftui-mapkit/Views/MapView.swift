import MapKit
import SwiftUI

// For now we have to wrap an MKMapView in a UIViewRepresenatable
// in order to use the iOS 16 MapKit features in SwiftUI.
struct MapView: UIViewRepresentable {
    var latitude: Double
    var longitude: Double
    var zoom: Double

    @EnvironmentObject private var mapSettings: MapSettings

    func makeUIView(context _: Context) -> MKMapView {
        let center = CLLocationCoordinate2D(
            latitude: latitude,
            longitude: longitude
        )
        let span = MKCoordinateSpan(
            latitudeDelta: zoom,
            longitudeDelta: zoom
        )
        let mapRegion = MKCoordinateRegion(center: center, span: span)

        let mapView = MKMapView(frame: .zero)
        mapView.region = mapRegion
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context _: Context) {
        switch mapSettings.type {
        case "standard":
            uiView.preferredConfiguration = MKStandardMapConfiguration(
                elevationStyle: elevationStyle(),
                emphasisStyle: emphasisStyle()
            )
        case "image":
            uiView.preferredConfiguration = MKImageryMapConfiguration(
                elevationStyle: elevationStyle()
            )
        case "hybrid":
            uiView.preferredConfiguration = MKHybridMapConfiguration(
                elevationStyle: elevationStyle()
            )
        default:
            break
        }
    }

    private func elevationStyle() -> MKMapConfiguration.ElevationStyle {
        mapSettings.elevation == "realistic" ?
            MKMapConfiguration.ElevationStyle.realistic :
            MKMapConfiguration.ElevationStyle.flat
    }

    private func emphasisStyle() -> MKStandardMapConfiguration.EmphasisStyle {
        mapSettings.emphasis == "muted" ?
            MKStandardMapConfiguration.EmphasisStyle.muted :
            MKStandardMapConfiguration.EmphasisStyle.default
    }
}
