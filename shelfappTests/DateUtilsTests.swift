//
//  DateUtilsTests.swift
//  shelfappTests
//
//  Tests for Date extension helpers.
//

import Testing
import Foundation
@testable import shelfapp

struct DateUtilsTests {

    @Test func daysFromNowPositive() {
        let future = Date.daysFromNow(7)
        let calendar = Calendar.current
        let dayDiff = calendar.dateComponents([.day], from: Date(), to: future).day ?? 0
        #expect(dayDiff == 7)
    }

    @Test func daysFromNowZero() {
        let now = Date.daysFromNow(0)
        let calendar = Calendar.current
        #expect(calendar.isDateInToday(now))
    }

    @Test func daysFromNowNegative() {
        let past = Date.daysFromNow(-3)
        let calendar = Calendar.current
        let dayDiff = calendar.dateComponents([.day], from: Date(), to: past).day ?? 0
        #expect(dayDiff == -3)
    }

    @Test func daysFromNowLargeValue() {
        let farFuture = Date.daysFromNow(365)
        #expect(farFuture > Date())
    }

    @Test func startOfDayResetsTimeComponents() {
        var components = DateComponents()
        components.year = 2026
        components.month = 3
        components.day = 26
        components.hour = 18
        components.minute = 45
        components.second = 12

        let date = Calendar.current.date(from: components)!
        let start = date.startOfDay
        let startComponents = Calendar.current.dateComponents([.hour, .minute, .second], from: start)

        #expect(startComponents.hour == 0)
        #expect(startComponents.minute == 0)
        #expect(startComponents.second == 0)
    }
}
