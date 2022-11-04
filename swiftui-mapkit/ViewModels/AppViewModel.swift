import SwiftUI

final class AppViewModel: ObservableObject {
    // The file "attractions.json" must be added to the project bundle.
    // - Select top entry in the file navigator.
    // - Select the app target.
    // - Select the "Build Phases" tab.
    // - Expand the "Copy Bundle Resources" section.
    // - Click the "+" button and select the file.
    // - Rebuild the app.
    // @Published var cities: [Area] =
    //    Bundle.main.decode([Area].self, from: "attractions.json")

    @Published var isSaving = false
    @Published var isSearching = false
    @Published var isSetting = false
    @Published var isShowingDirections = false
    @Published var mapElevation = "realistic" // other is "flat"
    @Published var mapEmphasis = "default" // other is "muted"
    @Published var mapType = "hybrid" // other are "standard" and "image"
    @Published var placeKind = ""
    @Published var preferMetric = false
    @Published var searchBy: String = "attraction"

    // These are here instead of being @State properties in SearchSheet.swift
    // because we want to persist the last values between uses of that view.
    @Published var selectedArea: Area?
    @Published var selectedAttraction: Attraction?

    static var shared = AppViewModel()

    private init() {} // makes this a singleton
}
