//
//  shelfappUITests.swift
//  shelfappUITests
//
//  Created by Andras Preisler on 2026. 02. 22..
//

import XCTest

// MARK: - Login & Signup Flow Tests

final class LoginUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: Login Screen Elements

    @MainActor
    func testLoginScreenShowsAppBranding() throws {
        XCTAssertTrue(app.staticTexts["Shelf Life"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Your personal inventory management system"].exists)
    }

    @MainActor
    func testLoginScreenShowsSegmentedPicker() throws {
        let loginSegment = app.buttons["Login"]
        let signUpSegment = app.buttons["Sign Up"]
        XCTAssertTrue(loginSegment.waitForExistence(timeout: 5))
        XCTAssertTrue(signUpSegment.exists)
    }

    @MainActor
    func testLoginFormFieldsExist() throws {
        XCTAssertTrue(app.textFields["Email"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.secureTextFields["Password"].exists)
    }

    @MainActor
    func testLoginButtonExistsAndDisabledWhenEmpty() throws {
        let loginButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Login'")).element(boundBy: 0)
        XCTAssertTrue(loginButton.waitForExistence(timeout: 5))
        XCTAssertFalse(loginButton.isEnabled)
    }

    @MainActor
    func testLoginButtonEnabledWhenFieldsFilled() throws {
        let emailField = app.textFields["Email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 5))
        emailField.tap()
        emailField.typeText("test@example.com")

        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText("password123")

        let loginButtons = app.buttons.matching(NSPredicate(format: "label == 'Login'"))
        let submitButton = loginButtons.element(boundBy: loginButtons.count - 1)
        XCTAssertTrue(submitButton.isEnabled)
    }

    // MARK: Signup Tab Tests

    @MainActor
    func testSwitchToSignUpTab() throws {
        let signUpSegment = app.buttons["Sign Up"]
        XCTAssertTrue(signUpSegment.waitForExistence(timeout: 5))
        signUpSegment.tap()

        XCTAssertTrue(app.textFields["Username"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.textFields["Email"].exists)
        XCTAssertTrue(app.secureTextFields["Password"].exists)
        XCTAssertTrue(app.secureTextFields["Confirm Password"].exists)
    }

    @MainActor
    func testSignUpButtonDisabledWhenEmpty() throws {
        let signUpSegment = app.buttons["Sign Up"]
        XCTAssertTrue(signUpSegment.waitForExistence(timeout: 5))
        signUpSegment.tap()

        let signUpButtons = app.buttons.matching(NSPredicate(format: "label == 'Sign Up'"))
        let submitButton = signUpButtons.element(boundBy: signUpButtons.count - 1)
        XCTAssertTrue(submitButton.waitForExistence(timeout: 3))
        XCTAssertFalse(submitButton.isEnabled)
    }

    @MainActor
    func testSignUpButtonEnabledWhenAllFieldsFilled() throws {
        let signUpSegment = app.buttons["Sign Up"]
        XCTAssertTrue(signUpSegment.waitForExistence(timeout: 5))
        signUpSegment.tap()

        let usernameField = app.textFields["Username"]
        XCTAssertTrue(usernameField.waitForExistence(timeout: 3))
        usernameField.tap()
        usernameField.typeText("testuser")

        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText("test@example.com")

        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText("password123")

        let confirmField = app.secureTextFields["Confirm Password"]
        confirmField.tap()
        confirmField.typeText("password123")

        let signUpButtons = app.buttons.matching(NSPredicate(format: "label == 'Sign Up'"))
        let submitButton = signUpButtons.element(boundBy: signUpButtons.count - 1)
        XCTAssertTrue(submitButton.isEnabled)
    }

    @MainActor
    func testSwitchBetweenLoginAndSignUp() throws {
        // Start on Login tab
        XCTAssertTrue(app.textFields["Email"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.textFields["Username"].exists)

        // Switch to Sign Up
        app.buttons["Sign Up"].tap()
        XCTAssertTrue(app.textFields["Username"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.secureTextFields["Confirm Password"].exists)

        // Switch back to Login
        let loginSegments = app.buttons.matching(NSPredicate(format: "label == 'Login'"))
        loginSegments.element(boundBy: 0).tap()

        XCTAssertTrue(app.textFields["Email"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.textFields["Username"].exists)
        XCTAssertFalse(app.secureTextFields["Confirm Password"].exists)
    }

    // MARK: Text Input Tests

    @MainActor
    func testEmailFieldAcceptsInput() throws {
        let emailField = app.textFields["Email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 5))
        emailField.tap()
        emailField.typeText("hello@test.com")
        XCTAssertEqual(emailField.value as? String, "hello@test.com")
    }

    @MainActor
    func testPasswordFieldIsSecure() throws {
        let passwordField = app.secureTextFields["Password"]
        XCTAssertTrue(passwordField.waitForExistence(timeout: 5))
        passwordField.tap()
        passwordField.typeText("secret")
        XCTAssertNotEqual(passwordField.value as? String, "secret")
    }

    // MARK: Performance

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}

// MARK: - Authenticated Flow Tests
// These tests verify the main app UI when the user is logged in.
// They require a running backend or test credentials.

final class AuthenticatedFlowUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    /// Helper: attempts to log in with test credentials.
    /// Returns true if the tab bar appears (authenticated state).
    @MainActor
    @discardableResult
    private func loginIfNeeded() -> Bool {
        if app.tabBars.firstMatch.waitForExistence(timeout: 3) {
            return true
        }

        let emailField = app.textFields["Email"]
        guard emailField.waitForExistence(timeout: 5) else { return false }
        emailField.tap()
        emailField.typeText("test@test.com")

        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText("test")

        let loginButtons = app.buttons.matching(NSPredicate(format: "label == 'Login'"))
        let submitButton = loginButtons.element(boundBy: loginButtons.count - 1)
        submitButton.tap()

        return app.tabBars.firstMatch.waitForExistence(timeout: 10)
    }

    // MARK: Tab Bar Navigation

    @MainActor
    func testTabBarShowsAllTabs() throws {
        guard loginIfNeeded() else {
            throw XCTSkip("Cannot authenticate - skipping authenticated flow tests")
        }

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.buttons["Home"].exists)
        XCTAssertTrue(tabBar.buttons["Notifications"].exists)
        XCTAssertTrue(tabBar.buttons["Profile"].exists)
    }

    @MainActor
    func testHomeTabIsDefaultSelected() throws {
        guard loginIfNeeded() else {
            throw XCTSkip("Cannot authenticate")
        }
        XCTAssertTrue(app.tabBars.buttons["Home"].isSelected)
    }

    @MainActor
    func testSwitchToNotificationsTab() throws {
        guard loginIfNeeded() else {
            throw XCTSkip("Cannot authenticate")
        }

        app.tabBars.buttons["Notifications"].tap()
        let noNotifications = app.staticTexts["No Notifications"]
        let invitationsHeader = app.staticTexts["Storage Invitations"]
        XCTAssertTrue(
            noNotifications.waitForExistence(timeout: 5) || invitationsHeader.waitForExistence(timeout: 5)
        )
    }

    @MainActor
    func testShoppingListShowsPlusMinusControlsWhenItemsExist() throws {
        guard loginIfNeeded() else {
            throw XCTSkip("Cannot authenticate")
        }

        let shoppingCard = app.staticTexts["Shopping List"]
        XCTAssertTrue(shoppingCard.waitForExistence(timeout: 5))
        shoppingCard.tap()

        XCTAssertTrue(app.navigationBars["Shopping List"].waitForExistence(timeout: 5))

        if app.staticTexts["No items to purchase"].exists {
            throw XCTSkip("Shopping list is empty")
        }

        XCTAssertTrue(app.buttons["shopping.plus"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["shopping.minus"].exists)
    }

    @MainActor
    func testShoppingListRowSwipeRevealsDoneAndDelete() throws {
        guard loginIfNeeded() else {
            throw XCTSkip("Cannot authenticate")
        }

        let shoppingCard = app.staticTexts["Shopping List"]
        XCTAssertTrue(shoppingCard.waitForExistence(timeout: 5))
        shoppingCard.tap()

        XCTAssertTrue(app.navigationBars["Shopping List"].waitForExistence(timeout: 5))

        if app.staticTexts["No items to purchase"].exists {
            throw XCTSkip("Shopping list is empty")
        }

        let firstCell = app.cells.firstMatch
        XCTAssertTrue(firstCell.waitForExistence(timeout: 5))
        firstCell.swipeLeft()

        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Delete"].exists)
    }

    @MainActor
    func testSwitchToProfileTab() throws {
        guard loginIfNeeded() else {
            throw XCTSkip("Cannot authenticate")
        }

        app.tabBars.buttons["Profile"].tap()
        XCTAssertTrue(app.staticTexts["Username"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Email"].exists)
    }

    // MARK: Home View

    @MainActor
    func testHomeViewShowsWelcomeText() throws {
        guard loginIfNeeded() else {
            throw XCTSkip("Cannot authenticate")
        }
        XCTAssertTrue(app.staticTexts["Welcome to Shelf Life"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Your personal inventory management system"].exists)
    }

    @MainActor
    func testHomeViewShowsStatCards() throws {
        guard loginIfNeeded() else {
            throw XCTSkip("Cannot authenticate")
        }
        XCTAssertTrue(app.staticTexts["Total Storages"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Items"].exists)
        XCTAssertTrue(app.staticTexts["Shopping List"].exists)
    }

    @MainActor
    func testStatCardNavigatesToStorages() throws {
        guard loginIfNeeded() else {
            throw XCTSkip("Cannot authenticate")
        }

        let storagesCard = app.staticTexts["Total Storages"]
        XCTAssertTrue(storagesCard.waitForExistence(timeout: 5))
        storagesCard.tap()

        let storagesTitle = app.navigationBars["Storages"]
        XCTAssertTrue(storagesTitle.waitForExistence(timeout: 5))
    }

    @MainActor
    func testStatCardNavigatesToProducts() throws {
        guard loginIfNeeded() else {
            throw XCTSkip("Cannot authenticate")
        }

        let itemsCard = app.staticTexts["Items"]
        XCTAssertTrue(itemsCard.waitForExistence(timeout: 5))
        itemsCard.tap()

        let productsTitle = app.navigationBars["Products"]
        XCTAssertTrue(productsTitle.waitForExistence(timeout: 5))
    }

    @MainActor
    func testStatCardNavigatesToShoppingList() throws {
        guard loginIfNeeded() else {
            throw XCTSkip("Cannot authenticate")
        }

        let shoppingCard = app.staticTexts["Shopping List"]
        XCTAssertTrue(shoppingCard.waitForExistence(timeout: 5))
        shoppingCard.tap()

        let shoppingTitle = app.navigationBars["Shopping List"]
        XCTAssertTrue(shoppingTitle.waitForExistence(timeout: 5))
    }

    // MARK: Storages View

    @MainActor
    func testStoragesViewContent() throws {
        guard loginIfNeeded() else {
            throw XCTSkip("Cannot authenticate")
        }

        let storagesCard = app.staticTexts["Total Storages"]
        XCTAssertTrue(storagesCard.waitForExistence(timeout: 5))
        storagesCard.tap()

        let noStorages = app.staticTexts["No Storages"]
        let myStorages = app.staticTexts["My Storages"]
        let sharedStorages = app.staticTexts["Shared with Me"]

        XCTAssertTrue(
            noStorages.waitForExistence(timeout: 5)
            || myStorages.waitForExistence(timeout: 5)
            || sharedStorages.waitForExistence(timeout: 5)
        )
    }

    @MainActor
    func testStoragesViewHasCreateButton() throws {
        guard loginIfNeeded() else {
            throw XCTSkip("Cannot authenticate")
        }

        let storagesCard = app.staticTexts["Total Storages"]
        XCTAssertTrue(storagesCard.waitForExistence(timeout: 5))
        storagesCard.tap()

        let addButton = app.navigationBars.buttons.matching(NSPredicate(format: "label CONTAINS 'Add'")).firstMatch
        let plusButton = app.navigationBars.buttons.matching(NSPredicate(format: "label CONTAINS 'plus'")).firstMatch
        let createStorageButton = app.buttons["Create Storage"]

        XCTAssertTrue(
            addButton.waitForExistence(timeout: 5)
            || plusButton.waitForExistence(timeout: 5)
            || createStorageButton.waitForExistence(timeout: 5)
        )
    }

    // MARK: Products View

    @MainActor
    func testProductsViewShows() throws {
        guard loginIfNeeded() else {
            throw XCTSkip("Cannot authenticate")
        }

        let itemsCard = app.staticTexts["Items"]
        XCTAssertTrue(itemsCard.waitForExistence(timeout: 5))
        itemsCard.tap()

        let productsNav = app.navigationBars["Products"]
        XCTAssertTrue(productsNav.waitForExistence(timeout: 5))

        let noProducts = app.staticTexts["No Products"]
        XCTAssertTrue(
            noProducts.exists
            || app.searchFields.firstMatch.exists
        )
    }

    // MARK: Profile View

    @MainActor
    func testProfileViewShowsAccountInfo() throws {
        guard loginIfNeeded() else {
            throw XCTSkip("Cannot authenticate")
        }

        app.tabBars.buttons["Profile"].tap()
        XCTAssertTrue(app.staticTexts["Username"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Email"].exists)
        XCTAssertTrue(app.staticTexts["Version"].exists)
        XCTAssertTrue(app.staticTexts["1.0.0"].exists)
        XCTAssertTrue(app.staticTexts["App Name"].exists)
    }

    @MainActor
    func testProfileViewShowsLogoutButton() throws {
        guard loginIfNeeded() else {
            throw XCTSkip("Cannot authenticate")
        }

        app.tabBars.buttons["Profile"].tap()
        let logoutButton = app.buttons["Logout"]
        XCTAssertTrue(logoutButton.waitForExistence(timeout: 5))
    }

    @MainActor
    func testProfileNavigatesToSettings() throws {
        guard loginIfNeeded() else {
            throw XCTSkip("Cannot authenticate")
        }

        app.tabBars.buttons["Profile"].tap()

        let appSettings = app.staticTexts["App Settings"]
        XCTAssertTrue(appSettings.waitForExistence(timeout: 5))
        appSettings.tap()

        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.switches["Push Notifications"].exists)
        XCTAssertTrue(app.switches["Dark Mode"].exists)
    }

    // MARK: Notifications View

    @MainActor
    func testNotificationsViewShowsState() throws {
        guard loginIfNeeded() else {
            throw XCTSkip("Cannot authenticate")
        }

        app.tabBars.buttons["Notifications"].tap()

        let noNotifications = app.staticTexts["No Notifications"]
        let caughtUp = app.staticTexts["You're all caught up!"]
        let invitationsHeader = app.staticTexts["Storage Invitations"]

        XCTAssertTrue(
            noNotifications.waitForExistence(timeout: 8)
            || caughtUp.waitForExistence(timeout: 8)
            || invitationsHeader.waitForExistence(timeout: 8)
        )
    }

    // MARK: Logout

    @MainActor
    func testLogoutReturnsToLoginScreen() throws {
        guard loginIfNeeded() else {
            throw XCTSkip("Cannot authenticate")
        }

        app.tabBars.buttons["Profile"].tap()

        let logoutButton = app.buttons["Logout"]
        XCTAssertTrue(logoutButton.waitForExistence(timeout: 5))
        logoutButton.tap()

        XCTAssertTrue(app.staticTexts["Shelf Life"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.textFields["Email"].exists)
    }

    // MARK: Back Navigation

    @MainActor
    func testBackNavigationFromStorages() throws {
        guard loginIfNeeded() else {
            throw XCTSkip("Cannot authenticate")
        }

        let storagesCard = app.staticTexts["Total Storages"]
        XCTAssertTrue(storagesCard.waitForExistence(timeout: 5))
        storagesCard.tap()

        XCTAssertTrue(app.navigationBars["Storages"].waitForExistence(timeout: 5))

        app.navigationBars.buttons.element(boundBy: 0).tap()

        XCTAssertTrue(app.staticTexts["Welcome to Shelf Life"].waitForExistence(timeout: 5))
    }
}
