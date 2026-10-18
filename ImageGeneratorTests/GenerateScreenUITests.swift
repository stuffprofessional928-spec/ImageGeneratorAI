import XCTest

final class GenerateScreenUITests: XCTestCase {
    func testPromptAreaGrowsWithEnteredText() {
        let app = XCUIApplication()
        app.launch()

        let promptCard = app.otherElements["prompt-card"]
        XCTAssertTrue(promptCard.waitForExistence(timeout: 5))
        let collapsedHeight = promptCard.frame.height

        let promptField = app.descendants(matching: .any)["image-prompt-field"]
        XCTAssertTrue(promptField.waitForExistence(timeout: 5))
        promptField.tap()
        promptField.typeText(String(repeating: "\nA new line of prompt text.", count: 8))

        XCTAssertGreaterThan(promptCard.frame.height, collapsedHeight)
    }

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
