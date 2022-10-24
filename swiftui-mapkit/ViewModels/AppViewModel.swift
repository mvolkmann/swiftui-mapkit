import SwiftUI

final class AppViewModel: ObservableObject {
    // The file "attractions.json" must be added to the project bundle.
    // - Select top entry in the file navigator.
    // - Select the app target.
    // - Select the "Build Phases" tab.
    // - Expand the "Copy Bundle Resources" section.
    // - Click the "+" button and select the file.
    // - Rebuild the app.
    @Published var cities: [City] =
        Bundle.main.decode([City].self, from: "attractions.json")

    @Published var isLiking = false
    @Published var isSearching = false
    @Published var isSetting = false
    @Published var mapElevation = "realistic" // other is "flat"
    @Published var mapEmphasis = "default" // other is "muted"
    @Published var mapType = "hybrid" // other are "standard" and "image"

    // These are here instead of being @State properties in SearchForm.swift
    // because we want to persist the last values between uses of that view.
    @Published var selectedAttractionIndex = -1
    // @Published var selectedCityIndex = -1
    @Published var selectedCityIndex = 0 // London
}
