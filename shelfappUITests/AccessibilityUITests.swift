//
//  AccessibilityUITests.swift
//  shelfappUITests
//
//  UI tests verifying accessibility and visual structure.
//

import XCTest

final class AccessibilityUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Login Screen Accessibility

    @MainActor
    func testLoginFormElementsAreAccessible() throws {
        let emailField = app.textFields["Email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 5))
        XCTAssertTrue(emailField.isEnabled)

        let passwordField = app.secureTextFields["Password"]
        XCTAssertTrue(passwordField.exists)
        XCTAssertTrue(passwordField.isEnabled)
    }

    @MainActor
    func testSignUpFormElementsAreAccessible() throws {
        let signUpSegment = app.buttons["Sign Up"]
        XCTAssertTrue(signUpSegment.waitForExistence(timeout: 5))
        signUpSegment.tap()

        XCTAssertTrue(app.textFields["Username"].isEnabled)
        XCTAssertTrue(app.textFields["Email"].isEnabled)
        XCTAssertTrue(app.secureTextFields["Password"].isEnabled)
        XCTAssertTrue(app.secureTextFields["Confirm Password"].isEnabled)
    }

    // MARK: - Keyboard Interaction

    @MainActor
    func testEmailFieldBringsUpKeyboard() throws {
        let emailField = app.textFields["Email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 5))
        emailField.tap()

        // Keyboard should appear
        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.waitForExistence(timeout: 3))
    }

    @MainActor
    func testSignUpFieldsCanBeFilledSequentially() throws {
        let signUpSegment = app.buttons["Sign Up"]
        XCTAssertTrue(signUpSegment.waitForExistence(timeout: 5))
        signUpSegment.tap()

        let fields = [
            app.textFields["Username"],
            app.textFields["Email"],
            app.secureTextFields["Password"],
            app.secureTextFields["Confirm Password"]
        ]

        for field in fields {
            XCTAssertTrue(field.waitForExistence(timeout: 3))
            field.tap()
            field.typeText("test")
        }

        // All fields should have values
        XCTAssertNotEqual(fields[0].value as? String, "Username")
        XCTAssertNotEqual(fields[1].value as? String, "Email")
    }
}

// MARK: - Edge Case UI Tests

final class EdgeCaseUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testRapidTabSwitchingOnLoginScreen() throws {
        let login = app.buttons["Login"]
        let signUp = app.buttons["Sign Up"]

        XCTAssertTrue(login.waitForExistence(timeout: 5))

        // Rapid switching should not crash
        for _ in 0..<5 {
            signUp.tap()
            login.tap()
        }

        // Should still be on login form
        XCTAssertTrue(app.textFields["Email"].exists)
    }

    @MainActor
    func testAppTitlePersistsAcrossTabSwitch() throws {
        XCTAssertTrue(app.staticTexts["Shelf Life"].waitForExistence(timeout: 5))

        app.buttons["Sign Up"].tap()
        XCTAssertTrue(app.staticTexts["Shelf Life"].exists)

        let loginSegments = app.buttons.matching(NSPredicate(format: "label == 'Login'"))
        loginSegments.element(boundBy: 0).tap()
        XCTAssertTrue(app.staticTexts["Shelf Life"].exists)
    }

    @MainActor
    func testLongTextInEmailField() throws {
        let emailField = app.textFields["Email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 5))
        emailField.tap()

        let longEmail = "averylongemailaddressthatgoeson@anditsverylongdomainname.com"
        emailField.typeText(longEmail)

        // Should not crash and field should contain text
        XCTAssertNotEqual(emailField.value as? String, "Email")
    }
}
