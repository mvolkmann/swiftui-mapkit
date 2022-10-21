import MapKit
import SwiftUI

// For now we have to wrap an MKMapView in a UIViewRepresenatable
// in order to use the iOS 16 MapKit features in SwiftUI.
struct MapView: UIViewRepresentable {
    var center: CLLocationCoordinate2D
    var zoom: Double

    typealias ElevationStyle = MKMapConfiguration.ElevationStyle
    typealias EmphasisStyle = MKStandardMapConfiguration.EmphasisStyle

    @EnvironmentObject private var appVM: AppViewModel
    @EnvironmentObject private var coreLocationVM: CoreLocationViewModel
    @EnvironmentObject private var mapKitVM: MapKitViewModel

    @State private var annotations: [MKPointAnnotation] = []
    @State private var titleToPlaceMap: [String: Place] = [:]

    private func elevationStyle() -> ElevationStyle {
        appVM.mapElevation == "realistic" ?
            ElevationStyle.realistic : ElevationStyle.flat
    }

    private func emphasisStyle() -> EmphasisStyle {
        appVM.mapEmphasis == "muted" ?
            EmphasisStyle.muted : EmphasisStyle.default
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true

        let span = MKCoordinateSpan(
            latitudeDelta: zoom,
            longitudeDelta: zoom
        )
        mapView.region = MKCoordinateRegion(center: center, span: span)

        // Save a reference to the MKMapView so
        // ContentView can obtain the center coordinate.
        Task {
            await MainActor.run {
                mapKitVM.mapView = mapView
            }
        }

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context _: Context) {
        var config: MKMapConfiguration!

        switch appVM.mapType {
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

        mapView.centerCoordinate = center
        coreLocationVM.region.center = center

        updateAnnotations(mapView)
    }

    private func updateAnnotations(_ mapView: MKMapView) {
        Task {
            await MainActor.run {
                let newAnnotations = coreLocationVM.places.map { place in
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = place.coordinate
                    annotation.title = place.displayName
                    // annotation.title = place.displayName + "\n" + place.address
                    // annotation.subtitle = place.address // not displayed

                    titleToPlaceMap[annotation.title!] = place

                    return annotation
                }

                mapView.removeAnnotations(annotations)
                mapView.addAnnotations(newAnnotations)
                annotations = newAnnotations
            }
        }
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }

        @MainActor
        func mapView(_: MKMapView, didSelect annotation: MKAnnotation) {
            if let title = annotation.title,
               // TODO: Why is force unwrap needed here?
               let place = parent.titleToPlaceMap[title!] {
                parent.coreLocationVM.selectedPlace = place
            }
        }
    }
}
