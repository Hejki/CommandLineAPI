/*
 *  CommandLineAPI
 *
 *  Copyright (c) 2019 Hejki. Licensed under the MIT license, as follows:
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the  Software), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in all
 *  copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED  AS IS, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *  SOFTWARE.
 */

@testable import CommandLineAPI
import XCTest

final class EnvTests: XCTestCase {

    func testEnv_get() {
        XCTAssertFalse(CLI.env.keys.isEmpty)
        XCTAssertEqual(CLI.env["TEST_ENV_VAR"], "varval")
    }

    func testEnv_set() {
        XCTAssertNil(CLI.env["TEST_ENV_VAR2"])

        CLI.env["TEST_ENV_VAR2"] = "newvarval"
        XCTAssertEqual(CLI.env["TEST_ENV_VAR2"], "newvarval")

        CLI.env["TEST_ENV_VAR2"] = nil
        XCTAssertFalse(CLI.env.keys.contains("TEST_ENV_VAR2"))
        XCTAssertNil(CLI.env["TEST_ENV_VAR2"])
    }
}
