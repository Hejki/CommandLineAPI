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

final class PathInitTests: XCTestCase {

    func testCommonPaths() throws {
        XCTAssertEqual(Path.root.path, "/")
        try XCTAssertEqual(Path.current.path, Path(FileManager.default.currentDirectoryPath).path)
        XCTAssertEqual(Path.home.path, NSHomeDirectory())

        #if os(macOS)
        XCTAssertEqual(Path.temporary.path.hasPrefix("/var/folders/"), true)
        #else
        XCTAssertEqual(Path.temporary.path.hasPrefix("/tmp"), true)
        #endif
    }

    func testInit() throws {
        let currentHome = NSHomeDirectory()
        let userName = try CLI.run("whoami | tr -d $'\n'")

        expectInit(path: "/", toBe: "/")
        expectInit(path: "/tmp", toBe: "/tmp")
        expectInit(path: "~", toBe: currentHome)
        expectInit(path: "~/tmp", toBe: currentHome + "/tmp")
        expectInit(path: "~\(userName)/tmp", toBe: NSHomeDirectoryForUser(userName)! + "/tmp")
        expectInit(path: "/tmp/..", toBe: "/")
        expectInit(path: "/../.././tmp/../.", toBe: "/")
        expectInit(path: "tmp", toBe: try Path(FileManager.default.currentDirectoryPath).path + "/tmp")

        #if os(macOS)
        expectInit(path: "/private/tmp", toBe: "/tmp")
        #endif
    }

    private func expectInit(path: String, toBe expectedPath: String) {
        let tested = try! Path(path)

        XCTAssertEqual(tested.path, expectedPath)
    }

    func testInit_url() {
        XCTAssertEqual(try Path(url: URL(fileURLWithPath: "/tmp")).path, "/tmp")
        XCTAssertThrowsError(try Path(url: URL(string: "http://test.com")!)) { error in
            if case let Path.Error.invalidURLScheme(scheme) = error {
                XCTAssertEqual(scheme, "http")
            } else {
                XCTFail("Bad error thrown \(error)")
            }
        }
        XCTAssertThrowsError(try Path(url: URL(string: "test.com")!)) { error in
            if case let Path.Error.invalidURLScheme(scheme) = error {
                XCTAssertEqual(scheme, "nil")
            } else {
                XCTFail("Bad error thrown \(error)")
            }
        }
    }

    func testInit_failes() {
        XCTAssertThrowsError(try Path("~nonexistuser/a")) { error in
            if case let Path.Error.cannotResolvePath(path) = error {
                XCTAssertEqual(path, "~nonexistuser")
            } else {
                XCTFail("Bad error thrown \(error)")
            }
        }
    }

    func testInit_relative() {
        XCTAssertEqual(Path("/as/a", relativeTo: Path(stringArgument: "/tmp")!).path, "/tmp/as/a")
    }
}
