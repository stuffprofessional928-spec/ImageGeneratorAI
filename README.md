# ImageGenerator

An iPhone SwiftUI MVP with placeholder controls and a local mock image-generation API. Model names are request metadata; no live AI provider is called.

## Run

1. From the project root, start the mock server: `python3 mock_server/server.py`.
2. Open `ios_mobile/ImageGenerator.xcodeproj` in Xcode and run the `ImageGenerator` scheme on an iPhone simulator.
3. Run unit and simulator UI tests with `xcodebuild test -project ios_mobile/ImageGenerator.xcodeproj -scheme ImageGenerator -destination 'platform=iOS Simulator,name=iPhone 17'`. Keep the mock server running while tests run.
4. Run mock API integration tests with `python3 -m unittest discover -s mock_server -v`.

The app starts with an example prompt and default options. Nothing is saved between launches. The local server is reachable from the simulator at `127.0.0.1:8787`; a physical device would require the host computer's LAN address.
