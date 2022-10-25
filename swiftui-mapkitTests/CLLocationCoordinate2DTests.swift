import CoreLocation
import XCTest

@testable import swiftui_mapkit
final class CLLocationCoordinate2DTests: XCTestCase {
    // Latitudes are horizontal lines on a globe
    // that specify north/south location.
    // They must be in the range -90 ... 90.
    // Longitudes are vertical lines on a globe
    // that specify east/west location.
    // They must be in the range -180 ... 180.
    let latDegrees1 = 50.0
    let latDegrees2 = 55.0
    let lngDegrees1 = 60.0
    let lngDegrees2 = 62.5

    let mapHeightDegrees = 20.0
    let mapWidthDegrees = 15.0

    var coord1: CLLocationCoordinate2D!
    var coord2: CLLocationCoordinate2D!
    var coord3: CLLocationCoordinate2D!

    override func setUpWithError() throws {
        // Put setup code here. This method is called
        // before the invocation of each test method in the class.
        coord1 = CLLocationCoordinate2D(
            latitude: latDegrees1,
            longitude: lngDegrees1
        )
        // coord2 is above coord1 by 5 degrees.
        coord2 = CLLocationCoordinate2D(
            latitude: latDegrees2,
            longitude: lngDegrees1
        )
        // coord3 is to the right of coord1 by 2.5 degrees.
        coord3 = CLLocationCoordinate2D(
            latitude: latDegrees1,
            longitude: lngDegrees2
        )
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called
        // after the invocation of each test method in the class.
    }

    func testLatitudeDifference() throws {
        let angle = coord1.latitudeDifference(to: coord2)
        XCTAssertEqual(angle, 5.0)
    }

    func testLatitudeDistance() throws {
        let height = coord1.latitudeDistance(degrees: mapHeightDegrees)
        let expectedHeight = 716_422.9751242305
        XCTAssertGreaterThan(height, expectedHeight)
    }

    func testLongitudeDifference() throws {
        let angle = coord1.longitudeDifference(to: coord3)
        XCTAssertEqual(angle, 2.5)
    }

    func testLongitudeDistance() throws {
        let width = coord1.longitudeDistance(degrees: mapWidthDegrees)
        let expectedWidth = 1_073_629.823344872
        XCTAssertEqual(width, expectedWidth)
    }
}
