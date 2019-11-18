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

final class AttributesTests: XCTestCase {
//
//    override func setUp() {
//        try? dataFile.delete()
//        _ = try? "a".write(to: dataFile)
//    }

    func testType() throws {
        expect(Path.root.appending("/tmp").type) == .symlink

        try Path.createTemporaryDirectory { dir in
            expect(dir.type) == .directory
            expect(dir.appending("nonexist").type) == .unknown

            let file = try dir.touch("file")
            expect(file.type) == .file

            let pipe = dir.appending("pipe")
            _ = CLI.run("mkfifo", pipe.path)
            expect(pipe.type) == .pipe
        }
    }

    func testDates() throws {
        try Path.createTemporaryDirectory { dir in
            let file = try dir.touch("data").write(text: "a")
            let attributes = file.attributes!

            try file.touch()
            expect(attributes).notTo(beNil())
            expect(attributes.modificationDate) < file.attributes!.modificationDate
            expect(attributes.creationDate) < file.attributes!.modificationDate
        }
    }

    func testAttributes() throws {
        expect(try Path("/nonexist").attributes).to(beNil())

        try Path.createTemporaryDirectory { dir in
            let file = try dir.touch("data").write(text: "a")
            let attributes = file.attributes!

            expect(attributes).notTo(beNil())
            expect(attributes.extensionHidden) == false
            expect(attributes.groupName) == "staff"
            if #available(OSX 10.12, *) {
                expect(attributes.userName) == ProcessInfo.processInfo.userName
            }
            expect(attributes.permissions.rawValue) == 0o644
            expect(attributes.size) == 1
        }
    }

    func testModifyAttributes() throws {
        try Path.createTemporaryDirectory { dir in
            let file = try dir.touch("data").write(text: "a")
            var attributes = file.attributes!

            let date = Date(timeIntervalSinceNow: -5)

            attributes.creationDate = date
            attributes.modificationDate = date.addingTimeInterval(3)
            attributes.permissions = Path.Permissions(rawValue: 0o777)
            attributes.groupName = "staff"

            expect(attributes.creationDate) == date
            expect(attributes.modificationDate) == date.addingTimeInterval(3)
            expect(attributes.permissions.rawValue) == 0o777
            expect(attributes.groupName) == "staff"

            try attributes.reload()
            expect(attributes.creationDate) == date
            expect(attributes.modificationDate) == date.addingTimeInterval(3)
            expect(attributes.permissions.rawValue) == 0o777
            expect(attributes.groupName) == "staff"
        }
    }

    func testModifyAttributes_macOS() throws {
        try Path.createTemporaryDirectory { dir in
            let file = try dir.touch("data").write(text: "a")
            var attributes = file.attributes!

            attributes.extensionHidden = true

            expect(attributes.extensionHidden) == true

            try attributes.reload()
            expect(attributes.extensionHidden) == true
        }
    }
}
