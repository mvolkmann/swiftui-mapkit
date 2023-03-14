import CloudKit
import SwiftUI

final class CloudKitViewModel: ObservableObject {
    private static let containerId =
        "iCloud.r.mark.volkmann.gmail.com.swiftui-mapkit"

    // MARK: - State

    @EnvironmentObject private var errorVM: ErrorViewModel

    @Published var areas: [Area] = []

    // MARK: - Initializer

    // This class is a singleton.
    private init() {
        cloudKit = CloudKit(containerId: Self.containerId)
        Task {
            await load()
        }
    }

    // MARK: - Properties

    static var shared = CloudKitViewModel()

    private var cloudKit: CloudKit!

    // MARK: - Methods

    private func addAttractionToArea(
        _ attraction: Attraction
    ) async throws -> Area? {
        let areaName = attraction.area

        // Find the area of the attraction.
        var area = areas.first(where: {
            area in area.name == areaName
        })

        // If the area doesn't exist, create it.
        if area == nil {
            area = try await createArea(name: areaName)
        }

        // We can't use "if let" here
        // because we need to mutate the area.
        area!.addAttraction(attraction)

        return area
    }

    @MainActor
    func createArea(name: String) async throws -> Area {
        let record = CKRecord(recordType: "Areas")
        record.setValue(
            name.trim() as CKRecordValue,
            forKey: "name"
        )

        let area = Area(record: record)
        try await cloudKit.create(item: area)

        areas.append(area)
        areas.sort { $0.name < $1.name }

        return area
    }

    @MainActor
    func createAttraction(
        area: String,
        name: String,
        latitude: Double,
        longitude: Double,
        distance: Double,
        heading: Double,
        pitch: Double
    ) async throws {
        let record = CKRecord(recordType: "Attractions")
        record.setValuesForKeys([
            "area": area,
            "name": name.trim(),
            "latitude": latitude,
            "longitude": longitude,
            "distance": distance,
            "heading": heading,
            "pitch": pitch
        ])
        let attraction = Attraction(record: record)
        try await cloudKit.create(item: attraction)

        do {
            if let area = try await addAttractionToArea(attraction) {
                area.sortAttractions()
            }
        } catch {
            errorVM.alert(
                error: error,
                message: "Failed to create attraction."
            )
        }
    }

    @MainActor
    func deleteArea(_ area: Area) async throws {
        // Delete all the attractions associated with the area.
        for attraction in area.attractions {
            try await deleteAttraction(area: area, attraction: attraction)
        }

        // Delete the area.
        try await cloudKit.delete(item: area)
        areas.removeAll(where: { $0 == area })
    }

    private func deleteAttraction(
        area: Area,
        offset: IndexSet.Element
    ) async throws {
        try await deleteAttraction(
            area: area,
            attraction: area.attractions[offset]
        )
    }

    @MainActor
    private func deleteAttraction(
        area: Area,
        attraction: Attraction
    ) async throws {
        try await cloudKit.delete(item: attraction)
        area.attractions.removeAll(where: { $0.name == attraction.name })
    }

    func deleteAttractions(area: Area, offsets: IndexSet) async throws {
        for offset in offsets {
            try await deleteAttraction(area: area, offset: offset)
        }
    }

    func load() async {
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

            _ = await MainActor.run {
                Task {
                    // Associate attractions with areas.
                    for attraction in attractions {
                        _ = try await addAttractionToArea(attraction)
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
            errorVM.alert(
                error: error,
                message: "Failed to load attractions."
            )
        }
    }

    @MainActor
    private func retrieveAreas() async throws {
        let areas = try await cloudKit.retrieve(
            recordType: "Areas",
            sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)]
        ) as [Area]
        self.areas = areas
    }

    @MainActor
    private func retrieveAttractions() async throws -> [Attraction] {
        try await cloudKit.retrieve(
            recordType: "Attractions",
            sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)]
        ) as [Attraction]
    }

    func updateItem(_ item: CloudKitable) async throws {
        try await cloudKit.update(item: item)
    }
}
