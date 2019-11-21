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
import Nimble
import XCTest

final class PathInitTests: XCTestCase {

    func testCommonPaths() throws {
        expect(Path.root.path) == "/"
        try expect(Path.current.path) == Path(FileManager.default.currentDirectoryPath).path
        expect(Path.home.path) == NSHomeDirectory()
        expect(Path.temporary.path.hasPrefix("/var/folders/")) == true
    }

    @available(OSX 10.12, *)
    func testInit() throws {
        let currentHome = NSHomeDirectory()
        let userName = ProcessInfo.processInfo.userName

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

        expect(tested.path) == expectedPath
    }

    func testInit_url() {
        expect(try Path(url: URL(fileURLWithPath: "/tmp")).path) == "/tmp"
        expect(try Path(url: URL(string: "http://test.com")!)).to(throwError(Path.Error.invalidURLScheme("http")))
        expect(try Path(url: URL(string: "test.com")!)).to(throwError(Path.Error.invalidURLScheme("nil")))
    }

    func testInit_failes() {
        expect(try Path("~nonexistuser/a")).to(throwError(Path.Error.cannotResolvePath("~nonexistuser")))
    }

    func testInit_relative() {
        expect(Path("/as/a", relativeTo: Path(stringArgument: "/tmp")!).path) == "/tmp/as/a"
    }
}
