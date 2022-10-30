import MapKit
import SwiftUI

// For now we have to wrap an MKMapView in a UIViewRepresenatable
// in order to use the iOS 16 MapKit features in SwiftUI.
struct MapView: UIViewRepresentable {
    var center: CLLocationCoordinate2D // holds lat/lng angles in degrees
    var distance: Double // in meters

    typealias ElevationStyle = MKMapConfiguration.ElevationStyle
    typealias EmphasisStyle = MKStandardMapConfiguration.EmphasisStyle

    @StateObject private var appVM = AppViewModel.shared
    @StateObject private var mapKitVM = MapKitViewModel.shared

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

    // This handles changes made in SettingsSheet.
    private func getConfig() -> MKMapConfiguration {
        var config: MKMapConfiguration!

        switch appVM.mapType {
        case "standard":
            let standard = MKStandardMapConfiguration(
                elevationStyle: elevationStyle(),
                emphasisStyle: emphasisStyle()
            )
            // showsTraffic is a property of MKStandardMapConfiguration,
            // but not a property of MKMapConfiguration.
            // This adds colored lines (yellow, red, and maroon)
            // to roads only in the standard view.
            standard.showsTraffic = true

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
            standard.pointOfInterestFilter = MKPointOfInterestFilter(
                // including: [.park, .theater]
                including: []
            )

            config = standard
        case "image":
            config = MKImageryMapConfiguration(
                elevationStyle: elevationStyle()
            )
        case "hybrid":
            let hybrid = MKHybridMapConfiguration(
                elevationStyle: elevationStyle()
            )
            hybrid.pointOfInterestFilter = MKPointOfInterestFilter(
                including: []
            )
            config = hybrid
        default:
            break
        }

        return config
    }

    // This is required to conform to UIViewRepresentable.
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // This is required to conform to UIViewRepresentable.
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator

        // This adds a blue circle over the current user location.
        mapView.showsUserLocation = true

        mapView.camera = MKMapCamera(
            lookingAtCenter: center,
            fromDistance: distance,
            pitch: 0.0,
            heading: 0.0
        )

        // Save a reference to the MKMapView
        // so SaveSheet can obtain the current center coordinate.
        // This must be done on the main queue.
        Task {
            await MainActor.run {
                mapKitVM.mapView = mapView
            }
        }

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context _: Context) {
        // Update the map with changes in SettingSheet.
        Task {
            await MainActor.run {
                mapView.preferredConfiguration = getConfig()
            }
        }

        // Update annotations for places like parks and restaurants.
        updateAnnotations(mapView)

        if appVM.shouldUpdateCamera, let center = mapKitVM.center {
            Task {
                await MainActor.run {
                    mapView.preferredConfiguration = getConfig()
                    mapView.camera = MKMapCamera(
                        lookingAtCenter: center,
                        fromDistance: mapKitVM.distance,
                        pitch: mapKitVM.pitch,
                        heading: mapKitVM.heading
                    )
                    appVM.shouldUpdateCamera = false
                }
            }
        }
    }

    // This adds annotations for places like parks and restaurants.
    private func updateAnnotations(_ mapView: MKMapView) {
        Task {
            await MainActor.run {
                let newAnnotations = mapKitVM.places.map { place in
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = place.coordinate
                    annotation.title = place.displayName
                    titleToPlaceMap[annotation.title!] = place
                    return annotation
                }

                mapView.removeAnnotations(annotations) // previous ones
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

        // This is called when an annotation is tapped.
        // It allows displaying the name, phone number, address, and website
        // of the place associated with the annotation.
        @MainActor
        func mapView(_: MKMapView, didSelect annotation: MKAnnotation) {
            // annotation.title has the following optional-optional type:
            // type optional var title: String? { get }
            if let optionalTitle = annotation.title,
               let title = optionalTitle,
               let place = parent.titleToPlaceMap[title] {
                parent.mapKitVM.selectedPlace = place
            }
        }
    }
}
