import Foundation

extension Date {
    static func daysFromNow(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
    }

    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}
