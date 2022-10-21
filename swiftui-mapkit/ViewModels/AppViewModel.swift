import SwiftUI

final class AppViewModel: ObservableObject {
    @Published var isSearching = false
    @Published var isSetting = false
    @Published var mapElevation = "realistic" // other is "flat"
    @Published var mapEmphasis = "default" // other is "muted"
    @Published var mapType = "hybrid" // other are "standard" and "image"

    // These are here instead of being @State properties in SearchForm.swift
    // because we want to persist the last values between uses of that view.
    @Published var selectedAttractionIndex = -1
    @Published var selectedCityIndex = -1
}
