import Flutter
import UIKit
import XCTest

final class VortixaRunnerSmokeTests: XCTestCase {
  func testRunnerHostIsPresent() {
    XCTAssertNotNil(UIApplication.shared)
  }
}
