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

final class AttributesTests: XCTestCase {

    func testType() throws {
        try Path.temporary { dir in
            XCTAssertEqual(dir.type, .directory)
            XCTAssertEqual(dir.appending("nonexist").type, .unknown)

            let file = try dir.touch("file")
            XCTAssertEqual(file.type, .file)

            let pipe = dir.appending("pipe")
            try CLI.run("mkfifo", pipe.path.quoted)
            XCTAssertEqual(pipe.type, .pipe)

            let symlink = dir.appending("link")
            try CLI.run("ln -s", file.path.quoted, symlink.path.quoted)
            XCTAssertEqual(symlink.type, .symlink)
        }
    }

    func testDates() throws {
        try Path.temporary { dir in
            let file = try dir.touch("data").write(text: "a")
            let attributes = file.attributes!

            try file.touch()
            XCTAssertNotNil(attributes)
            XCTAssertNotNil(attributes.modificationDate)

            #if os(macOS)
            XCTAssertLessThan(attributes.modificationDate, file.attributes!.modificationDate)
            XCTAssertLessThan(attributes.creationDate!, file.attributes!.modificationDate)
            #endif
        }
    }

    func testAttributes() throws {
        XCTAssertNil(try Path("/nonexist").attributes)

        try Path.temporary { dir in
            let file = try dir.touch("data").write(text: "a")
            let attributes = file.attributes!

            XCTAssertNotNil(attributes)
            try XCTAssertEqual(attributes.groupName, CLI.run("groups $(whoami) | cut -d' ' -f1 | tr -d $'\n'"))
            try XCTAssertEqual(attributes.userName, CLI.run("whoami | tr -d $'\n'"))
            XCTAssertEqual(attributes.size, 1)

            #if os(macOS)
            XCTAssertEqual(attributes.permissions.rawValue, 0o644)
            #else
            XCTAssertEqual(attributes.permissions.rawValue, 0o600)
            #endif
        }
    }

    func testModifyAttributes() throws {
        #if os(macOS)
        try Path.temporary { dir in
            let file = try dir.touch("data").write(text: "a")
            var attributes = file.attributes!

            let date = Date(timeIntervalSinceNow: -5)

            attributes.creationDate = date
            attributes.modificationDate = date.addingTimeInterval(3)
            attributes.permissions = Path.Permissions(rawValue: 0o777)
            attributes.groupName = "staff"

            XCTAssertEqual(attributes.creationDate, date)
            XCTAssertEqual(attributes.modificationDate, date.addingTimeInterval(3))
            XCTAssertEqual(attributes.permissions.rawValue, 0o777)
            XCTAssertEqual(attributes.groupName, "staff")

            try attributes.reload()
            XCTAssertEqual(attributes.creationDate, date)
            XCTAssertEqual(attributes.modificationDate, date.addingTimeInterval(3))
            XCTAssertEqual(attributes.permissions.rawValue, 0o777)
            XCTAssertEqual(attributes.groupName, "staff")
        }
        #endif
    }

    func testModifyAttributes_macOS() throws {
        #if os(macOS)
        try Path.temporary { dir in
            let file = try dir.touch("data").write(text: "a")
            var attributes = file.attributes!

            attributes.extensionHidden = true

            XCTAssertEqual(attributes.extensionHidden, true)

            try attributes.reload()
            XCTAssertEqual(attributes.extensionHidden, true)
        }
        #endif
    }
}
