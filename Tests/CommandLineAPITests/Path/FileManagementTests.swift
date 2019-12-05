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

final class FileManagementTests: XCTestCase {

    func testExist() {
        XCTAssertEqual(Path.root.exist, true)
        XCTAssertEqual(try Path("/kjdsnfk").exist, false)
    }

    func testCopy_file() throws {
        try file(move: false)
    }

    func testMove_file() throws {
        try file(move: true)
    }

    private func file(move: Bool) throws {
        try Path.temporary { dir in
            let destFile = try dir.createDirectory("sub").appending("new.txt")
            let file = try dir.touch("file")

            let target = try move ? file.move(to: destFile) : file.copy(to: destFile)

            XCTAssertEqual(file.exist, !move)
            XCTAssertEqual(target.type, .file)
            XCTAssertEqual(target.path(relativeTo: dir), "sub/new.txt")
        }
    }

    func testCopy_fileToDirectory() throws {
        try fileToDirectory(move: false)
    }

    func testMove_fileToDirectory() throws {
        try fileToDirectory(move: true)
    }

    private func fileToDirectory(move: Bool) throws {
        try Path.temporary { dir in
            let subdir = try dir.createDirectory("sub")
            let file = try dir.touch("file")

            let target = try move ? file.move(to: subdir) : file.copy(to: subdir)

            XCTAssertEqual(file.exist, !move)
            XCTAssertEqual(target.type, .file)
            XCTAssertEqual(target.path(relativeTo: dir), "sub/file")
        }
    }

    func testCopy_fileToFileExist() throws {
        try fileToFileExist(move: false)
    }

    func testMove_fileToFileExist() throws {
        try fileToFileExist(move: true)
    }

    private func fileToFileExist(move: Bool) throws {
        try Path.temporary { dir in
            let dst = try dir.createDirectory("sub").touch("new.txt")
            let file = try dir.touch("file")

            XCTAssertThrowsError(try move ? file.move(to: dst) : file.copy(to: dst))

            let target = try move
                ? file.move(to: dst, overwrite: true)
                : file.copy(to: dst, overwrite: true)

            XCTAssertEqual(file.exist, !move)
            XCTAssertEqual(target.type, .file)
            XCTAssertEqual(target.path(relativeTo: dir), "sub/new.txt")
        }
    }

    func testCopy_directory() throws {
        try directory(move: false)
    }

    func testMove_directory() throws {
        try directory(move: true)
    }

    private func directory(move: Bool) throws {
        try Path.temporary { dir in
            let origin = try dir.createDirectory("a/b").touch("file")
                .parent.parent
            let dst = try dir.createDirectory("sub").appending("newdir")

            let target = try move ? origin.move(to: dst) : origin.copy(to: dst)

            XCTAssertEqual(origin.exist, !move)
            XCTAssertEqual(target.type, .directory)
            XCTAssertEqual(target.path(relativeTo: dir), "sub/newdir")
            XCTAssertEqual(target.appending("b/file").type, .file)
        }
    }

    func testCopy_directoryToDirectory() throws {
        try directoryToDirectory(move: false)
    }

    func testMove_directoryToDirectory() throws {
        try directoryToDirectory(move: true)
    }

    private func directoryToDirectory(move: Bool) throws {
        try Path.temporary { dir in
            let origin = try dir.createDirectory("a/b").touch("file")
                .parent.parent
            let subdir = try dir.createDirectory("sub")

            let target = try move ? origin.move(to: subdir) : origin.copy(to: subdir)

            XCTAssertEqual(origin.exist, !move)
            XCTAssertEqual(target.type, .directory)
            XCTAssertEqual(target.path(relativeTo: dir), "sub/a")
            XCTAssertEqual(target.appending("b/file").type, .file)
        }
    }

    func testCopy_directoryToFileExist() throws {
        try directoryToFileExist(move: false)
    }

    func testMove_directoryToFileExist() throws {
        try directoryToFileExist(move: true)
    }

    private func directoryToFileExist(move: Bool) throws {
        try Path.temporary { dir in
            let dst = try dir.createDirectory("sub").touch("exist")
            let origin = try dir.createDirectory("a/b").touch("file")
                .parent.parent

            XCTAssertThrowsError(try move ? origin.move(to: dst) : origin.copy(to: dst))

            let target = try move
                ? origin.move(to: dst, overwrite: true)
                : origin.copy(to: dst, overwrite: true)

            XCTAssertEqual(origin.exist, !move)
            XCTAssertEqual(target.type, .directory)
            XCTAssertEqual(target.path(relativeTo: dir), "sub/exist")
            XCTAssertEqual(target.appending("b/file").type, .file)
        }
    }

    func testTouch_name() throws {
        try Path.temporary { dir in
            XCTAssertEqual(try dir.touch("file").type, .file)
            XCTAssertEqual(try dir.appending("a").touch().type, .file)
            XCTAssertThrowsError(try dir.touch("b/c"))

            try dir.createDirectory("d")

            XCTAssertEqual(try dir.touch("d/c").path(relativeTo: dir), "d/c")
        }
    }

    func testCreateDirectory() throws {
        try Path.temporary { dir in
            var d = try dir.createDirectory("a")

            XCTAssertEqual(d.type, .directory)
            XCTAssertEqual(d.path(relativeTo: dir), "a")

            d = try dir.appending("b").createDirectory("a")
            XCTAssertEqual(d.type, .directory)
            XCTAssertEqual(d.path(relativeTo: dir), "b/a")

            d = try dir.appending("c").createDirectory()
            XCTAssertEqual(d.type, .directory)
            XCTAssertEqual(d.path(relativeTo: dir), "c")

            d = try d.createDirectory("../b/a/../d")
            XCTAssertEqual(d.type, .directory)
            XCTAssertEqual(d.path(relativeTo: dir), "b/d")
        }
    }

    func testDelete() throws {
        try Path.temporary { dir in
            var p = try dir.touch("a")
            try p.delete()
            XCTAssertEqual(p.exist, false)

            p = try dir.createDirectory("a/b")
            try p.parent.delete()
            XCTAssertEqual(p.exist, false)
            XCTAssertEqual(p.parent.exist, false)
        }
    }

    func testTrash() throws {
        #if os(macOS)
        try Path.temporary { dir in
            let trash = try Path(url: FileManager.default.url(for: .trashDirectory, in: .userDomainMask, appropriateFor: nil, create: false)).appending("a")
            let p = try dir.touch("a")

            if trash.exist { try trash.delete() }
            XCTAssertEqual(trash.exist, false)
            try p.delete(useTrash: true)
            XCTAssertEqual(p.exist, false)
            XCTAssertEqual(trash.exist, true)
        }
        #endif
    }

    func testRename() throws {
        try Path.temporary { dir in
            let file = try dir.touch("old.txt")
            let renamed = try file.rename(to: "new")

            XCTAssertEqual(renamed.path(relativeTo: dir), "new")
            XCTAssertThrowsError(try renamed.rename(to: "a/s"))
        }
    }
}
