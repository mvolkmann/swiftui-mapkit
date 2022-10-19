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
    @EnvironmentObject private var vm: ViewModel

    @State private var annotations: [MKPointAnnotation] = []

    private func elevationStyle() -> ElevationStyle {
        mapSettings.elevation == "realistic" ?
            ElevationStyle.realistic : ElevationStyle.flat
    }

    private func emphasisStyle() -> EmphasisStyle {
        mapSettings.emphasis == "muted" ?
            EmphasisStyle.muted : EmphasisStyle.default
    }

    func makeUIView(context _: Context) -> MKMapView {
        print("MapView.makeUIView entered")
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

    func updateUIView(_ mapView: MKMapView, context _: Context) {
        print("UPDATE UI VIEW ENTERED")
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

            // pointOfInterestFilter is a property of MKStandardMapConfiguration,
            // but not a property of MKMapConfiguration.
            // By default many points of interest are displayed
            // in the standard map view (not in image or hybrid).
            // Setting this limits the types that are shown which can include:
            // airport, amusementPark, aquarium, atm,
            // bakery, bank, beach, brewery,
            // cafe, campground, carRental, evCharger,
            // fireStation, fitnessCenter, foodMarket,
            // gasStation, hospital, hotel, laundry, library,
            // marina, movieTheater, museum, nationalPark, nightlife,
            // park, parking, pharmacy, police, postOffice, publicTransport,
            // restaurant, restroom, school, stadium, store, theater,
            // university, winery, and zoo.
            temp.pointOfInterestFilter = MKPointOfInterestFilter(
                including: [.park, .theater]
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

        mapView.preferredConfiguration = config

        updateAnnotations(mapView)
    }

    private func updateAnnotations(_ mapView: MKMapView) {
        Task {
            await MainActor.run {
                let newAnnotations = vm.places.map { place in
                    var annotation = MKPointAnnotation()
                    annotation.coordinate = place.coordinate
                    annotation.title = place.displayName
                    return annotation
                }
                mapView.removeAnnotations(annotations)
                mapView.addAnnotations(newAnnotations)
                annotations = newAnnotations
            }
        }
    }
}
