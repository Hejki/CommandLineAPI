import XCTest

import CommandLineAPITests

var tests = [XCTestCaseEntry]()
tests += CommandLineAPITests.__allTests()

XCTMain(tests)
