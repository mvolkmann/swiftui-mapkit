import CoreLocation

struct City: Codable, Hashable, Identifiable {
    let name: String
    var attractions: [Attraction] = []

    var id: String { name }
}

/*
 private func setup() -> [City] {
     // The file "attractions.json" must be added to the project bundle.
     // - Select top entry in the file navigator.
     // - Select the app target.
     // - Select the "Build Phases" tab.
     // - Expand the "Copy Bundle Resources" section.
     // - Click the "+" button and select the file.
     // - Rebuild the app.
     Bundle.main.decode([City].self, from: "attractions.json")
 }

 let cities = setup()
 */
let cities: [City] = Bundle.main.decode([City].self, from: "attractions.json")
