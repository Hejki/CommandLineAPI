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

final class PathOtherTests: XCTestCase {

    func testEqualAndHash() throws {
        try Path.createTemporaryDirectory { dir in
            let a = try dir.createDirectory("a")
            let b = try Path(url: a.url)

            expect(a) == b
            expect(b) == a
            expect(a) != dir
            expect(a.hashValue) == b.hashValue
        }
    }

    func testComparable() {
        expect(Path.current.appending("a")) < Path.current.appending("b")
        expect(Path.current.appending("a/b")) > Path.current.appending("a/a")
    }

    func testBundle() throws {
        try Path.createTemporaryDirectory { dir -> Void in
            guard let bundle = Bundle(path: dir.path) else {
                return fail("Couldn't make bundle for \(dir.path)")
            }

            let filePath = try dir.touch("file.txt")
            let resPath: Path? = bundle.path(forResource: "file", withExtension: "txt")
            let nilPath: Path? = bundle.path(forResource: "nonexist", withExtension: "txt")

            expect(bundle.path) == dir
            expect(resPath) == filePath
            expect(nilPath).to(beNil())
        }
    }

    func testErrorDecriptions() throws {
        let e: [Path.Error] = [
            .cannotResolvePath("path"),
            .invalidURLScheme("http"),
            .invalidArgumentValue(arg: "arg", "description"),
        ]
        let msg = [
            "Cannot resolve path: 'path'",
            "URL scheme: 'http' is not supported. Only 'file' can be used.",
            "Invalid argument: 'arg' value. description",
        ]

        for (e, msg) in zip(e, msg) {
            expect(e.localizedDescription) == msg
        }
    }

    func testCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let fullPath = "/mypath/file.txt"

        let encoded = try encoder.encode(Path.root.appending(fullPath))
        expect(String(data: encoded, encoding: .utf8)) == "\"\\/mypath\\/file.txt\""

        var decoded = try decoder.decode(Path.self, from: encoded)
        expect(decoded.path) == fullPath

        decoded = try decoder.decode(Path.self, from: "\"/mypath/file.txt\"".data(using: .utf8)!)
        expect(decoded.path) == fullPath
    }
}
