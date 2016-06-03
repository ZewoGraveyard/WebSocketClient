#if os(Linux)

import XCTest
@testable import WebSocketClientTestSuite

XCTMain([
  testCase(WebSocketClientTests.allTests),
])
#endif
