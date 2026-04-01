//
//  NavigationManagerTests.swift
//  shelfappTests
//
//  Tests for NavigationMananger.
//

import Testing
import SwiftUI
@testable import shelfapp

struct NavigationManagerTests {

    @Test func sharedInstanceExists() {
        let manager = NavigationMananger.shared
        #expect(manager != nil)
    }

    @Test func popToRootResetsPath() {
        let manager = NavigationMananger.shared
        manager.path.append("TestRoute")
        #expect(manager.path.count > 0)

        manager.popToRoot()
        #expect(manager.path.count == 0)
    }

    @Test func multiplePopToRootIsSafe() {
        let manager = NavigationMananger.shared
        manager.popToRoot()
        manager.popToRoot()
        #expect(manager.path.count == 0)
    }
}
