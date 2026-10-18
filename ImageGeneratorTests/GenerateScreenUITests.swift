import XCTest

final class GenerateScreenUITests: XCTestCase {
    func testDimensionsCanBeSelected() {
        let app = XCUIApplication()
        app.launch()

        let dimensionsButton = app.buttons["dimensions-option"]
        XCTAssertTrue(dimensionsButton.waitForExistence(timeout: 5))
        dimensionsButton.tap()

        let widescreenDimensions = app.buttons["dimension-1K-16:9"]
        XCTAssertTrue(widescreenDimensions.waitForExistence(timeout: 5))
        widescreenDimensions.tap()

        XCTAssertTrue(dimensionsButton.label.contains("1024 × 576"))
    }

    func testGenerateAndSaveMockImage() {
        let app = XCUIApplication()
        app.launch()

        let generateButton = app.buttons["Generate"]
        XCTAssertTrue(generateButton.waitForExistence(timeout: 5))
        generateButton.tap()

        let viewButton = app.buttons["View"]
        XCTAssertTrue(viewButton.waitForExistence(timeout: 15))
        let downloadButton = app.buttons["Download"]
        XCTAssertTrue(downloadButton.exists)
        XCTAssertTrue(viewButton.isHittable)
        XCTAssertTrue(downloadButton.isHittable)
        downloadButton.tap()

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allowButton = springboard.alerts.buttons["Allow"]
        if allowButton.waitForExistence(timeout: 3) {
            allowButton.tap()
        }

        XCTAssertTrue(app.staticTexts["Saved to Photos."].waitForExistence(timeout: 10))
    }
}
