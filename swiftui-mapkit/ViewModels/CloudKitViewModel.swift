import CloudKit
import SwiftUI

class CloudKitViewModel: ObservableObject {
    // MARK: - State

    @Published var areas: [Area] = []

    private static let containerId =
        "iCloud.r.mark.volkmann.gmail.com.swiftui-mapkit"

    // MARK: - Initializer

    // This class is a singleton.
    private init() {
        cloudKit = CloudKit(containerId: Self.containerId)
        Task {
            do {
                let statusText = try await cloudKit.statusText()
                guard statusText == "available" else {
                    Log.info(
                        "CloudKitViewModel.init: CloudKit is not available"
                    )
                    return
                }

                try await retrieveAreas()
                let attractions = try await retrieveAttractions()

                Task {
                    await MainActor.run {
                        // Associate attractions with areas.
                        for attraction in attractions {
                            let _ = addAttractionToArea(attraction)
                        }

                        // We cannot iterate over the areas and mutate them
                        // but we can iterate over the indices
                        // and mutate the area objects found by index.
                        for index in areas.indices {
                            areas[index].sortAttractions()
                        }
                    }
                }
            } catch {
                Log.error(error)
            }
        }
    }

    // MARK: - Properties

    static var shared = CloudKitViewModel()

    private var cloudKit: CloudKit!

    // MARK: - Methods

    private func addAttractionToArea(_ attraction: Attraction) -> Area? {
        let areaName = attraction.area

        // Find the area of the attraction.
        let area = areas.first(where: {
            area in area.name == areaName
        })

        // We can't use "if let" here
        // because we need to mutate the area.
        if area != nil {
            area!.addAttraction(attraction)
        }

        return area
    }

    func createArea(name: String) async throws -> Area {
        let record = CKRecord(recordType: "Areas")
        record.setValue(
            name.trim() as CKRecordValue,
            forKey: "name"
        )

        let area = Area(record: record)
        try await cloudKit.create(item: area)

        DispatchQueue.main.sync {
            self.areas.append(area)
            self.areas.sort { $0.name < $1.name }
        }

        return area
    }

    func createAttraction(
        area: String,
        name: String,
        latitude: Double,
        longitude: Double,
        radius: Double,
        heading: Double,
        pitch: Double
    ) async throws {
        let record = CKRecord(recordType: "Attractions")
        record.setValuesForKeys([
            "area": area,
            "name": name.trim(),
            "latitude": latitude,
            "longitude": longitude,
            "radius": radius,
            "heading": heading,
            "pitch": pitch
        ])
        let attraction = Attraction(record: record)
        try await cloudKit.create(item: attraction)

        DispatchQueue.main.sync {
            if let area = addAttractionToArea(attraction) {
                area.sortAttractions()
            }
        }
    }

    func deleteArea(_ area: Area) async throws {
        try await cloudKit.delete(item: area)
        DispatchQueue.main.async {
            self.areas.removeAll(where: { $0 == area })
        }
    }

    private func deleteAttraction(
        area: Area,
        offset: IndexSet.Element
    ) async throws {
        let attraction = area.attractions[offset]
        try await cloudKit.delete(item: attraction)
        DispatchQueue.main.async {
            area.attractions.remove(at: offset)
        }
    }

    func deleteAttractions(area: Area, offsets: IndexSet) async throws {
        for offset in offsets {
            try await deleteAttraction(area: area, offset: offset)
        }
    }

    func retrieveAreas() async throws {
        let areas = try await cloudKit.retrieve(
            recordType: "Areas",
            sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)]
        ) as [Area]
        DispatchQueue.main.sync { self.areas = areas }
    }

    func retrieveAttractions() async throws -> [Attraction] {
        try await cloudKit.retrieve(
            recordType: "Attractions",
            sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)]
        ) as [Attraction]
    }
}
