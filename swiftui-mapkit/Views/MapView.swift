import MapKit
import SwiftUI

// For now we have to wrap an MKMapView in a UIViewRepresenatable
// in order to use the iOS 16 MapKit features in SwiftUI.
struct MapView: UIViewRepresentable {
    var latitude: Double
    var longitude: Double
    var zoom: Double

    typealias ElevationStyle = MKMapConfiguration.ElevationStyle
    typealias EmphasisStyle = MKStandardMapConfiguration.EmphasisStyle

    @EnvironmentObject private var mapSettings: MapSettings

    private func elevationStyle() -> ElevationStyle {
        mapSettings.elevation == "realistic" ?
            ElevationStyle.realistic : ElevationStyle.flat
    }

    private func emphasisStyle() -> EmphasisStyle {
        mapSettings.emphasis == "muted" ?
            EmphasisStyle.muted : EmphasisStyle.default
    }

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
        var config: MKMapConfiguration!

        switch mapSettings.type {
        case "standard":
            let temp = MKStandardMapConfiguration(
                elevationStyle: elevationStyle(),
                emphasisStyle: emphasisStyle()
            )
            // showsTraffic is a property of MKStandardMapConfiguration,
            // but not a property of MKMapConfiguration.
            // This adds colored lines (yellow, red, and maroon)
            // to roads only in the standard view.
            temp.showsTraffic = true

            // Likewise for pointOfInterestFilter.
            temp.pointOfInterestFilter = MKPointOfInterestFilter(
                including: [.bakery]
            )

            config = temp
        case "image":
            config = MKImageryMapConfiguration(
                elevationStyle: elevationStyle()
            )
        case "hybrid":
            config = MKHybridMapConfiguration(
                elevationStyle: elevationStyle()
            )
        default:
            break
        }

        uiView.preferredConfiguration = config
    }
}
