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

final class FilesystemRepresentationTests: XCTestCase {
    let tmp = Path.root.appending("/tmp")
    let dataFile = Path.root.appending("/tmp/data.txt")

    func testParent() throws {
        expect(Path.root.parent.path) == "/"
        expect(Path.root.parent.parent.path) == "/"
        expect(self.tmp.parent.path) == "/"
        expect(self.dataFile.parent.path) == "/tmp"
        expect(self.dataFile.parent.parent.path) == "/"
    }

    func testChildren() throws {
        try Path.createTemporaryDirectory { tmp in
            let file1 = try tmp.touch("a")
            let file2 = try tmp.touch("b")
            let dir1 = try tmp.createDirectory("c")
            let hiddenDir = try tmp.createDirectory(".f")
            let fileInsideDir = try dir1.touch("g")

            var all = tmp.children.compactMap { $0 }
            expect(all).to(haveCount(3))
            expect(all).to(contain(file1, file2, dir1))

            all = tmp.children.recursive.compactMap { $0 }
            expect(all).to(haveCount(4))
            expect(all).to(contain(file1, file2, dir1, fileInsideDir))

            all.removeAll()
            for p in tmp.children.includingHidden {
                all.append(p)
            }
            expect(all).to(haveCount(4))
            expect(all).to(contain(file1, file2, dir1, hiddenDir))
        }
    }

    func testPathComponents() {
        expect(self.dataFile.pathComponents) == ["tmp", "data.txt"]
        expect(Path.root.pathComponents) == []
    }

    func testBasename() {
        expect(self.dataFile.basename) == "data.txt"
        expect(self.tmp.basename) == "tmp"
        expect(try Path("/a.tar.gz").basename) == "a.tar.gz"
    }

    func testExtension() throws {
        expect(self.dataFile.extension) == "txt"
        expect(self.tmp.extension) == ""
        expect(try Path("/a.tar.gz").extension) == "tar.gz"
    }

    func testBasenameWithoutExtension() {
        expect(self.dataFile.basenameWithoutExtension) == "data"
        expect(self.tmp.basenameWithoutExtension) == "tmp"
        expect(try Path("/a.tar.gz").basenameWithoutExtension) == "a"
    }

    func testRelativePath() throws {
        try Path.createTemporaryDirectory { dir in
            let a = try dir.createDirectory("a")
            let ab = try a.createDirectory("b")
            let acd = try a.createDirectory("c/d")
            let abc = try ab.createDirectory("c")

            // "/a/b".path(relativeTo: "/a") == "b"
            expect(ab.path(relativeTo: a)) == "b"

            // "/a/b/c".path(relativeTo: "/a") == "b/c"
            expect(abc.path(relativeTo: a)) == "b/c"

            // "/a/b".path(relativeTo: "/a/b/c") == ".."
            expect(ab.path(relativeTo: abc)) == ".."

            // "/a/b".path(relativeTo: "/a/c/d") == "../../b"
            expect(ab.path(relativeTo: acd)) == "../../b"
        }
    }

    func testAppending() {
        expect(Path.root.appending("/").path) == "/"
        expect(self.tmp.appending("/a/").path) == "/tmp/a"
        expect(self.tmp.appending("../a").path) == "/a"
        expect(self.tmp.appending("../../.././a").path) == "/a"
        expect((self.tmp + "/tmp/.././a").path) == "/tmp/a"

        let p: String? = nil
        expect(self.tmp.appending(p).path) == "/tmp"

        var b = tmp + "b"
        b += "../c"
        expect(b.path) == "/tmp/c"
    }
}
