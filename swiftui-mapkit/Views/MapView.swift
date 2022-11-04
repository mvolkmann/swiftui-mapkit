import MapKit
import SwiftUI

// For now we have to wrap an MKMapView in a UIViewRepresenatable
// in order to use the iOS 16 MapKit features in SwiftUI.
struct MapView: UIViewRepresentable {
    typealias ElevationStyle = MKMapConfiguration.ElevationStyle
    typealias EmphasisStyle = MKStandardMapConfiguration.EmphasisStyle
    typealias UIViewType = MKMapView

    var center: CLLocationCoordinate2D // holds lat/lng angles in degrees
    var distance: Double // in meters

    @StateObject private var appVM = AppViewModel.shared
    @StateObject private var mapKitVM = MapKitViewModel.shared

    @State private var annotations: [MKPointAnnotation] = []
    @State private var annotationToPlaceMap: [MKPointAnnotation: Place] = [:]

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
    func makeUIView(context: Context) -> UIViewType {
        let mapView = UIViewType()
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
        mainQ { mapKitVM.mapView = mapView }

        return mapView
    }

    @MainActor
    func updateUIView(_ mapView: UIViewType, context _: Context) {
        // I was getting the error "The following Metal object is being
        // destroyed while still required to be alive by the command buffer".
        // This thread provided a solution:
        // https://developer.apple.com/forums/thread/699119
        // I had to edit the current Xcode scheme, click "Run" in the left nav,
        // and uncheck the "API Validation" checkbox in the "Metal" section.

        Task {
            // Update the map with changes in SettingSheet.
            mapView.preferredConfiguration = getConfig()

            // Update annotations for places like parks and restaurants.
            updateAnnotations(mapView)

            if mapKitVM.shouldUpdateCamera, let center = mapKitVM.center {
                mapView.preferredConfiguration = getConfig()
                let currentCenter = mapView.camera.centerCoordinate
                let newCamera = MKMapCamera(
                    lookingAtCenter: center,
                    fromDistance: mapKitVM.distance,
                    pitch: mapKitVM.pitch,
                    heading: mapKitVM.heading
                )
                let isClose = center.isCloseTo(currentCenter)
                mapView.setCamera(newCamera, animated: isClose)
                mapKitVM.shouldUpdateCamera = false

                // Add a circle annotation with a 30 meter radius
                // at the center location.
                let overlay = MKCircle(center: center, radius: 30.0)
                mapView.addOverlay(overlay)
            }
        }
    }

    // This adds annotations for places like parks and restaurants.
    private func updateAnnotations(_ mapView: UIViewType) {
        mainQ {
            let newAnnotations = mapKitVM.places.map { place in
                let annotation = MKPointAnnotation()
                annotation.coordinate = place.coordinate
                annotation.title = place.displayName

                /*
                 if place == mapKitVM.selectedPlace {
                     // Why doesn't calling this update mapView.selectedAnnotations!
                     mapView.selectAnnotation(annotation, animated: true)
                     print("selected", place)
                 }
                 */

                annotationToPlaceMap[annotation] = place

                return annotation
            }

            mapView.removeAnnotations(annotations) // previous ones
            mapView.addAnnotations(newAnnotations)
            annotations = newAnnotations
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
        func mapView(
            _: UIViewType,
            didSelect annotation: MKAnnotation
        ) {
            guard annotation is MKPointAnnotation else { return }

            if let place = parent
                .annotationToPlaceMap[annotation as! MKPointAnnotation] {
                parent.mapKitVM.selectedPlace = place

                // This doesn't seem to provide any benefit.
                // The view.setSelected call below takes care of this.
                // mapView.selectAnnotation(annotation, animated: true)
            }
        }

        func mapView(_: UIViewType, regionDidChangeAnimated _: Bool) {
            Task {
                do {
                    try await parent.mapKitVM.lookAroundUpdate()
                } catch {
                    Log.error("error updating look around: \(error)")
                }
            }
        }

        /// This returns a renderer for a given overlay.
        func mapView(
            _: UIViewType,
            rendererFor overlay: MKOverlay
        ) -> MKOverlayRenderer {
            // Provided subclasses of MKOverlayRenderer include
            // - MKCircleRenderer - fills and strokes a circle
            // - MKPolylineRenderer - like MKPolygonRender but
            //   doesn't fill because the shape isn't necessarily closed
            // - MKPolygonRenderer - fills and strokes
            // - MKOverlayPathRenderer - renders shape defined by a CGPath
            // - MKTileOverlayRenderer for bitmap images
            // - MKGradientPolygonRenderer - like MKPolylineRenderer
            //   but uses gradient color
            // - MKMultiPolygonRenderer - renders multiple polygons
            // - MKMultiPolylineRenderer - renders multiple polylines
            if let overlay = overlay as? MKCircle {
                let renderer = MKCircleRenderer(overlay: overlay)
                renderer.fillColor = .red
                renderer.alpha = 0.2
                return renderer
            }

            if let overlay = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(overlay: overlay)
                renderer.strokeColor = .blue
                renderer.lineWidth = 5
                return renderer
            }

            // This is used when we get an overlay type
            // that isn't handled above.
            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(
            _ mapView: MKMapView,
            viewFor annotation: MKAnnotation
        ) -> MKAnnotationView? {
            // Do not show the user location annotation.
            if annotation is MKUserLocation { return nil }

            // Create an annotation view or reuse an existing one.
            var view: MKMarkerAnnotationView
            let identifier = "place-annotation"
            if let dequeuedView = mapView.dequeueReusableAnnotationView(
                withIdentifier: identifier
            ) as? MKMarkerAnnotationView {
                view = dequeuedView
                view.annotation = annotation
            } else {
                view = MKMarkerAnnotationView(
                    annotation: annotation,
                    reuseIdentifier: identifier
                )
            }

            // view.glyphTintColor = .red
            // view.markerTintColor = .yellow

            // mapView.selectedAnnotations is not updated
            // when mapView.selectAnnotation is called!

            let selectedPlace = parent.mapKitVM.selectedPlace
            let isSelected = selectedPlace?.coordinate == annotation.coordinate
            view.setSelected(isSelected, animated: true)

            return view
        }
    }
}
