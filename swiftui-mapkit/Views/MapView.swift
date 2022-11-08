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
    @State private var mapCenterOverlays: [MKOverlay] = []

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

    /// Computes a latitude angle from a latitude distance.
    /// - Parameters:
    ///   - latitude: span in meters
    /// - Returns: the latitude span angle in degrees
    private func latitudeAngle(
        latitudeMeters: Double
    ) -> Double {
        let earthCircumferenceThroughPoles = 40_007_863.0 // meters
        let metersPerDegree = earthCircumferenceThroughPoles / 360.0
        return latitudeMeters / metersPerDegree
    }

    /// Computes a longitude distance in meters.
    /// - Parameters:
    ///   - latitude: angle in degrees
    ///   - longitudeAngle: longitude span angle in degrees
    /// - Returns: the longitude span distance in meters
    private func longitudeMeters(
        latitude: Double,
        longitudeAngle: Double
    ) -> Double {
        let radiansPerDegree = Double.pi / 180.0
        let latRadians = latitude * radiansPerDegree
        let lngRadians = longitudeAngle * radiansPerDegree
        let earthRadius = 6_371_000.0 // average
        let earthDiameter = earthRadius * 2
        return earthDiameter * asin(cos(latRadians) * sin(lngRadians / 2))
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

        mapView.register(
            RouteAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: RouteAnnotation.identifier
        )

        return mapView
    }

    private func showCenter(mapView: MKMapView) {
        guard appVM.mapElevation == "flat" else { return }

        let screenWidthPercent = 0.05 // 5%

        let rect = mapView.visibleMapRect
        let eastPoint = MKMapPoint(x: rect.minX, y: rect.midY)
        let westPoint = MKMapPoint(x: rect.maxX, y: rect.midY)
        let radius = westPoint.distance(to: eastPoint) * screenWidthPercent

        let center = mapView.camera.centerCoordinate
        let lat = center.latitude
        let lng = center.longitude

        // Get the longitude angle that represents screenWidthPercent
        // across the width of the screen at the current zoom level.
        let lngAngle = mapView.region.span.longitudeDelta * screenWidthPercent

        // Get the distance of this longitude angle in meters.
        let lngMeters = longitudeMeters(
            latitude: lat,
            longitudeAngle: lngAngle
        )

        // Get the latitude angle that has the
        // same distance as the longitude angle.
        let latAngle = latitudeAngle(
            latitudeMeters: lngMeters
        )

        let bottom = CLLocationCoordinate2D(
            latitude: lat - latAngle,
            longitude: lng
        )
        let top = CLLocationCoordinate2D(
            latitude: lat + latAngle,
            longitude: lng
        )
        let left = CLLocationCoordinate2D(
            latitude: lat,
            longitude: lng - lngAngle
        )
        let right = CLLocationCoordinate2D(
            latitude: lat,
            longitude: lng + lngAngle
        )

        let color: UIColor = .red
        let lineWidth = 2.0

        let circle = MyCircle(center: center, radius: radius)
        circle.alpha = 1.0
        // circle.fillColor = .blue
        circle.lineWidth = lineWidth
        circle.strokeColor = color

        let line1 = MyPolyline(coordinates: [left, right], count: 2)
        line1.color = color
        line1.lineWidth = lineWidth

        let line2 = MyPolyline(coordinates: [bottom, top], count: 2)
        line2.color = color
        line2.lineWidth = lineWidth

        mapView.removeOverlays(mapCenterOverlays)
        mapCenterOverlays = [circle, line1, line2]
        mapView.addOverlays(mapCenterOverlays)
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

            let currentCenter = mapView.camera.centerCoordinate

            if mapKitVM.shouldUpdateCamera, let center = mapKitVM.center {
                mapView.preferredConfiguration = getConfig()
                let newCamera = MKMapCamera(
                    lookingAtCenter: center,
                    fromDistance: mapKitVM.distance,
                    pitch: mapKitVM.pitch,
                    heading: mapKitVM.heading
                )
                let isClose = center.isCloseTo(currentCenter)
                mapView.setCamera(newCamera, animated: isClose)
                mapKitVM.shouldUpdateCamera = false

                /*
                 // Add a circle annotation with a 30 meter radius
                 // at the camera center location.
                 let cameraOverlay = MKCircle(center: center, radius: 30.0)
                 mapView.addOverlay(cameraOverlay)
                 */
            }

            showCenter(mapView: mapView)
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
            _ mapView: UIViewType,
            didSelect annotation: MKAnnotation
        ) {
            if let annotation = annotation as? MKPointAnnotation,
               let place = parent.annotationToPlaceMap[annotation] {
                parent.mapKitVM.selectedPlace = place

                // This doesn't seem to provide any benefit.
                // The view.setSelected call below takes care of this.
                // mapView.selectAnnotation(annotation, animated: true)

                // Remove any route displays.
                mapView.removeOverlays(mapView.overlays)
            } else if let annotation = annotation as? RouteAnnotation {
                print("got route tap")
                parent.mapKitVM.selectedRoute = annotation.route
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
            if let overlay = overlay as? MKCircle {
                let renderer = MKCircleRenderer(overlay: overlay)
                if let overlay = overlay as? MyCircle {
                    renderer.alpha = overlay.alpha
                    renderer.fillColor = overlay.fillColor
                    renderer.strokeColor = overlay.strokeColor
                    renderer.lineWidth = overlay.lineWidth
                }
                return renderer
            }

            if let overlay = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(overlay: overlay)
                if let overlay = overlay as? MyPolyline {
                    renderer.strokeColor = overlay.color
                    renderer.lineWidth = overlay.lineWidth
                } else {
                    // These are for route lines.
                    renderer.strokeColor = .blue
                    renderer.lineWidth = 3
                }
                return renderer
            }

            // This is used when we get an overlay type
            // that isn't handled above.
            return MKOverlayRenderer(overlay: overlay)
        }

        /// This returns a view for a given annotation.
        func mapView(
            _ mapView: MKMapView,
            viewFor annotation: MKAnnotation
        ) -> MKAnnotationView? {
            // Do not show the user location annotation.
            if annotation is MKUserLocation { return nil }

            var view: MKAnnotationView

            if annotation is MKPointAnnotation {
                // Create an annotation view or reuse an existing one.
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

                if let view = view as? MKMarkerAnnotationView {
                    view.markerTintColor = UIColor.yellow // bubble color
                    // view.glyphTintColor = .red // pin color
                }

                // mapView.selectedAnnotations is not updated
                // when mapView.selectAnnotation is called!

                let selectedPlace = parent.mapKitVM.selectedPlace
                let isSelected = selectedPlace?.coordinate == annotation
                    .coordinate
                view.setSelected(isSelected, animated: true)
            } else if annotation is RouteAnnotation {
                if let dequeuedView = mapView.dequeueReusableAnnotationView(
                    withIdentifier: RouteAnnotation.identifier
                ) as? MKMarkerAnnotationView {
                    view = dequeuedView
                    view.annotation = annotation
                    view.canShowCallout = false // need this?
                } else {
                    view = RouteAnnotationView(
                        annotation: annotation,
                        reuseIdentifier: RouteAnnotation.identifier
                    )
                }
            } else {
                fatalError(
                    "Unsupported annotation type: \(type(of: annotation))"
                )
            }

            return view
        }
    }
}
