import MapKit
import SwiftUI

// For now we have to wrap an MKMapView in a UIViewRepresenatable
// in order to use the iOS 16 MapKit features in SwiftUI.
struct MapView: UIViewRepresentable {
    var center: CLLocationCoordinate2D // initial, not current
    var radius: Double

    typealias ElevationStyle = MKMapConfiguration.ElevationStyle
    typealias EmphasisStyle = MKStandardMapConfiguration.EmphasisStyle

    @EnvironmentObject private var appVM: AppViewModel
    @EnvironmentObject private var coreLocationVM: CoreLocationViewModel
    @StateObject var mapKitVM = MapKitViewModel.shared

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

        let newRegion = MKCoordinateRegion(
            center: center,
            latitudinalMeters: radius,
            longitudinalMeters: radius
        )
        mapView.setRegion(newRegion, animated: false)

        // Save a reference to the MKMapView so
        // LikeForm can obtain the current center coordinate.
        // This must be done on the main queue.
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

        mapView.preferredConfiguration = config

        if let center = mapKitVM.center {
            let radius = mapKitVM.radius
            let heading = mapKitVM.heading
            let pitch = mapKitVM.pitch

            let centerChanged = center != mapView.centerCoordinate
            // The radius property on MKCoordinateRegion
            // is a computed property that I added
            // in MKCoordinateRegionExtension.swift.
            let radiusChanged = radius != mapView.region.radius
            let headingChanged = heading != mapView.camera.heading
            let pitchChanged = pitch != mapView.camera.pitch

            /*
             if centerChanged {
                 print(
                     "center changed from \(mapView.region.center.description) to \(center.description)"
                 )
             }
             if radiusChanged {
                 print(
                     "radius changed from \(mapView.region.radius) to \(radius)"
                 )
             }
             if headingChanged { print("heading changed") }
             if pitchChanged { print("pitch changed") }
             */

            if centerChanged || radiusChanged || headingChanged ||
                pitchChanged {
                let newRegion = MKCoordinateRegion(
                    center: center,
                    latitudinalMeters: radius,
                    longitudinalMeters: radius
                )
                // TODO: Why is the newRegion span only honored in the first call?
                // let span = newRegion.span
                // print("MapView: span before =", span)
                mapView.setRegion(newRegion, animated: false)
                // mapView.region.span = span // This doesn't help.

                /*
                 // This is an attempt to fix the region span
                 // after the call to setRegion above.
                 let left = center.offset(
                     latitudeMeters: 0,
                     longitudeMeters: -radius
                 )
                 let right = center.offset(
                     latitudeMeters: 0,
                     longitudeMeters: radius
                 )
                 let latitudeAngle = left.latitudeDifference(to: right)
                 mapView.region.span.latitudeDelta = latitudeAngle

                 let bottom = center.offset(
                     latitudeMeters: -radius,
                     longitudeMeters: 0
                 )
                 let top = center.offset(
                     latitudeMeters: radius,
                     longitudeMeters: 0
                 )
                 let longitudeAngle = bottom.longitudeDifference(to: top)
                 mapView.region.span.longitudeDelta = longitudeAngle
                 */

                // print("MapView: span after =", mapView.region.span)
                // TODO: Why does this not match the previous print statement?

                mapView.camera.heading = heading
                mapView.camera.pitch = pitch
            }
        }

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

        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            Task {
                await MainActor.run {
                    let mapKitVM = parent.mapKitVM
                    let region = mapView.region
                    let camera = mapView.camera
                    mapKitVM.center = region.center
                    mapKitVM.radius = region.radius
                    mapKitVM.heading = camera.heading
                    mapKitVM.pitch = camera.pitch
                }
            }
        }
    }
}
