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

final class FilesystemRepresentationTests: XCTestCase {
    let tmp = Path.root.appending("/tmp")
    let dataFile = Path.root.appending("/tmp/data.txt")

    func testParent() throws {
        XCTAssertEqual(Path.root.parent.path, "/")
        XCTAssertEqual(Path.root.parent.parent.path, "/")
        XCTAssertEqual(self.tmp.parent.path, "/")
        XCTAssertEqual(self.dataFile.parent.path, "/tmp")
        XCTAssertEqual(self.dataFile.parent.parent.path, "/")
    }

    func testChildren() throws {
        try Path.temporary { tmp in
            let file1 = try tmp.touch("a")
            let file2 = try tmp.touch("b")
            let dir1 = try tmp.createDirectory("c")
            let hiddenDir = try tmp.createDirectory(".f")
            let fileInsideDir = try dir1.touch("g")

            var all = tmp.children
            XCTAssertEqual(all.count, 3)
            XCTAssertEqual(all.isEmpty, false)
            XCTAssertEqual(all.sorted(), [file1, file2, dir1])

            all = tmp.children.recursive
            XCTAssertEqual(all.count, 4)
            XCTAssertEqual(all.sorted(), [file1, file2, dir1, fileInsideDir])

            var array = [Path]()
            for p in tmp.children.includingHidden {
                array.append(p)
            }
            XCTAssertEqual(array.count, 4)
            XCTAssertTrue(array.contains(file1))
            XCTAssertTrue(array.contains(file2))
            XCTAssertTrue(array.contains(dir1))
            XCTAssertTrue(array.contains(hiddenDir))
        }

        let noChildren = Path.root.appending("nonexisttestfile").children
        XCTAssertEqual(noChildren.count, 0)
        XCTAssertEqual(noChildren.isEmpty, true)
    }

    func testPathComponents() {
        XCTAssertEqual(self.dataFile.pathComponents, ["tmp", "data.txt"])
        XCTAssertEqual(Path.root.pathComponents, [])
    }

    func testBasename() {
        XCTAssertEqual(self.dataFile.basename, "data.txt")
        XCTAssertEqual(self.tmp.basename, "tmp")
        XCTAssertEqual(try Path("/a.tar.gz").basename, "a.tar.gz")
    }

    func testExtension() throws {
        XCTAssertEqual(self.dataFile.extension, "txt")
        XCTAssertEqual(self.tmp.extension, "")
        XCTAssertEqual(try Path("/a.tar.gz").extension, "tar.gz")
    }

    func testBasenameWithoutExtension() {
        XCTAssertEqual(self.dataFile.basenameWithoutExtension, "data")
        XCTAssertEqual(self.tmp.basenameWithoutExtension, "tmp")
        XCTAssertEqual(try Path("/a.tar.gz").basenameWithoutExtension, "a")
    }

    func testRelativePath() throws {
        try Path.temporary { dir in
            let a = try dir.createDirectory("a")
            let ab = try a.createDirectory("b")
            let acd = try a.createDirectory("c/d")
            let abc = try ab.createDirectory("c")

            // "/a/b".path(relativeTo: "/a") == "b"
            XCTAssertEqual(ab.path(relativeTo: a), "b")

            // "/a/b/c".path(relativeTo: "/a") == "b/c"
            XCTAssertEqual(abc.path(relativeTo: a), "b/c")

            // "/a/b".path(relativeTo: "/a/b/c") == ".."
            XCTAssertEqual(ab.path(relativeTo: abc), "..")

            // "/a/b".path(relativeTo: "/a/c/d") == "../../b"
            XCTAssertEqual(ab.path(relativeTo: acd), "../../b")
        }
    }

    func testAppending() {
        XCTAssertEqual(Path.root.appending("/").path, "/")
        XCTAssertEqual(self.tmp.appending("/a/").path, "/tmp/a")
        XCTAssertEqual(self.tmp.appending("../a").path, "/a")
        XCTAssertEqual(self.tmp.appending("../../.././a").path, "/a")
        XCTAssertEqual((self.tmp + "/tmp/.././a").path, "/tmp/a")

        let p: String? = nil
        XCTAssertEqual(self.tmp.appending(p).path, "/tmp")

        var b = tmp + "b"
        b += "../c"
        XCTAssertEqual(b.path, "/tmp/c")
    }
}
