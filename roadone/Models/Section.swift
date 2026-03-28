// Section.swift

import Foundation
import MapKit

class Section: Identifiable, ObservableObject {
    let id = UUID()
    let ward: Int
    let sectionNumber: Int
    let hood: String
    @Published var cleaningDates: [Date] = []
    var overlays: [MKOverlay] = []

    init(ward: Int, sectionNumber: Int, hood: String) {
        self.ward = ward
        self.sectionNumber = sectionNumber
        self.hood = hood
    }

    func nextCleaningDates() -> [Date] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())

        let futureDates = cleaningDates
            .filter { calendar.startOfDay(for: $0) >= startOfToday }
            .sorted()

        let recentPastDates = cleaningDates
            .filter {
                let startOfDate = calendar.startOfDay(for: $0)
                if startOfDate >= startOfToday { return false }
                let diff = calendar.dateComponents([.day], from: startOfDate, to: startOfToday).day ?? 0
                return diff <= 2
            }
            .sorted(by: >)

        var result: [Date] = []
        result.append(contentsOf: futureDates.prefix(2))
        if result.count < 2 {
            result.append(contentsOf: recentPastDates.prefix(2 - result.count))
        }
        return result
    }

    /// Returns the single most relevant date for map coloring.
    /// Prefers the next future date; falls back to a recent past date (within 2 days).
    func dateForColoring() -> Date? {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())

        let nextFuture = cleaningDates
            .filter { calendar.startOfDay(for: $0) >= startOfToday }
            .sorted()
            .first

        if let future = nextFuture {
            return future
        }

        let recentPast = cleaningDates
            .filter {
                let startOfDate = calendar.startOfDay(for: $0)
                if startOfDate >= startOfToday { return false }
                let diff = calendar.dateComponents([.day], from: startOfDate, to: startOfToday).day ?? 0
                return diff <= 2
            }
            .sorted(by: >)
            .first

        return recentPast
    }
}
