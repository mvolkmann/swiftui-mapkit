import Foundation

extension Date {
    static func from(dateComponents: DateComponents) -> Date? {
        Calendar.current.date(from: dateComponents)
    }

    /// - Parameter seconds: Int number of seconds (assumes less than one day)
    /// - Returns: String time that is a given number of seconds from now
    static func hoursAndMinutesFromNow(seconds: Int) -> String {
        let date = Calendar.current.date(
            byAdding: .second,
            value: seconds,
            to: Date.now
        )!
        return date.hm
    }

    /// - Returns: String time of this date showing only hours and minutes
    var hm: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        return dateFormatter.string(from: self)
    }

    /// - Returns: String time of this date showing hours, minutes, and seconds
    var hms: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm:ss a"
        return dateFormatter.string(from: self)
    }
}
